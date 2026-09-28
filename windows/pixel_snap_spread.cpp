#include <algorithm>
#include <cmath>
#include <cstdint>
#include <thread>
#include <vector>

#if defined(_WIN32)
#define PIXEL_SNAP_EXPORT __declspec(dllexport)
#else
#define PIXEL_SNAP_EXPORT __attribute__((visibility("default")))
#endif

// Computes the per-grid spread scores from Dart's interval arrays and RGB/RGB²
// summed-area table. This is our own native implementation of the same
// arithmetic used by pixel_snap_core.dart; no NovelAI binary is linked.
// Keep the float32 conversion points in sync with _spread when changing this.
extern "C" PIXEL_SNAP_EXPORT int32_t pixel_snap_spread_v1(
    const int32_t* inner_start, const int32_t* inner_end,
    const uint8_t* inner_selected, int32_t batches, int32_t phases,
    int32_t inner_count, const int32_t* outer_start,
    const int32_t* outer_end, const uint8_t* outer_selected,
    int32_t outer_count, const uint32_t* sat, int32_t sat_length,
    int32_t sat_stride, int32_t inner_is_column, float* output) {
  if (!inner_start || !inner_end || !inner_selected || !outer_start ||
      !outer_end || !outer_selected || !sat || !output || batches <= 0 ||
      phases <= 0 || inner_count <= 0 || outer_count <= 0 ||
      sat_length <= 0 || sat_stride <= 0) {
    return -1;
  }

  const int32_t output_count = batches * phases;
  auto score_one = [&](int32_t out_index) {
    const int32_t batch = out_index / phases;
    const int32_t outer_base = batch * outer_count;
    int32_t outer_selected_count = 0;
    for (int32_t q = 0; q < outer_count; ++q) {
      outer_selected_count += outer_selected[outer_base + q] != 0;
    }
      const int32_t inner_base = out_index * inner_count;
      int32_t inner_selected_count = 0;
      for (int32_t q = 0; q < inner_count; ++q) {
        inner_selected_count += inner_selected[inner_base + q] != 0;
      }
      if (inner_selected_count < 3 || outer_selected_count < 3) {
        output[out_index] = 1.0e18f;
        return;
      }

      float accumulated = 0.0f;
      for (int32_t q = 0; q < outer_count; ++q) {
        if (outer_selected[outer_base + q] == 0) continue;
        const int32_t outer_lo = outer_start[outer_base + q];
        const int32_t outer_hi = outer_end[outer_base + q];
        for (int32_t cell = 0; cell < inner_count; ++cell) {
          if (inner_selected[inner_base + cell] == 0) continue;
          const int32_t inner_lo = inner_start[inner_base + cell];
          const int32_t inner_hi = inner_end[inner_base + cell];
          const int32_t r0 = inner_is_column ? outer_lo : inner_lo;
          const int32_t r1 = inner_is_column ? outer_hi : inner_hi;
          const int32_t c0 = inner_is_column ? inner_lo : outer_lo;
          const int32_t c1 = inner_is_column ? inner_hi : outer_hi;
          const int64_t area = static_cast<int64_t>(r1 - r0) * (c1 - c0);
          const int64_t o11 =
              (static_cast<int64_t>(r1) * sat_stride + c1) * 6;
          const int64_t o10 =
              (static_cast<int64_t>(r0) * sat_stride + c1) * 6;
          const int64_t o01 =
              (static_cast<int64_t>(r1) * sat_stride + c0) * 6;
          const int64_t o00 =
              (static_cast<int64_t>(r0) * sat_stride + c0) * 6;
          if (o11 < 0 || o10 < 0 || o01 < 0 || o00 < 0 ||
              o11 + 5 >= sat_length || o10 + 5 >= sat_length ||
              o01 + 5 >= sat_length || o00 + 5 >= sat_length) {
            continue;
          }

          float deviation = 0.0f;
          const float area32 = static_cast<float>(area);
          for (int32_t channel = 0; channel < 3; ++channel) {
            const uint32_t sum = sat[o11 + channel] - sat[o10 + channel] -
                                 sat[o01 + channel] + sat[o00 + channel];
            const uint32_t sum_sq = sat[o11 + channel + 3] -
                                    sat[o10 + channel + 3] -
                                    sat[o01 + channel + 3] +
                                    sat[o00 + channel + 3];
            int64_t variance = area * sum_sq -
                               static_cast<int64_t>(sum) * sum;
            if (variance < 0) variance = 0;
            const float variance32 = static_cast<float>(variance);
            const float root32 =
                static_cast<float>(std::sqrt(static_cast<double>(variance32)));
            const float term32 = static_cast<float>(
                static_cast<double>(root32) / static_cast<double>(area32));
            deviation = static_cast<float>(
                static_cast<double>(deviation) + static_cast<double>(term32));
          }
          const float score32 =
              static_cast<float>(static_cast<double>(deviation) / 3.0);
          accumulated = static_cast<float>(
              static_cast<double>(accumulated) + static_cast<double>(score32));
        }
      }
      const float divisor = static_cast<float>(
          static_cast<double>(static_cast<float>(outer_selected_count)) *
          static_cast<double>(static_cast<float>(inner_selected_count)));
      output[out_index] = static_cast<float>(
          static_cast<double>(accumulated) / static_cast<double>(divisor));
  };

  const int64_t estimated_pairs = static_cast<int64_t>(output_count) *
                                  inner_count * outer_count;
  const unsigned hardware_threads = std::thread::hardware_concurrency();
  const int32_t thread_count = estimated_pairs < 1000000
                                   ? 1
                                   : std::min<int32_t>(
                                         output_count,
                                         std::min<int32_t>(
                                             8, hardware_threads == 0
                                                    ? 4
                                                    : hardware_threads));
  if (thread_count == 1) {
    for (int32_t index = 0; index < output_count; ++index) {
      score_one(index);
    }
  } else {
    std::vector<std::thread> workers;
    workers.reserve(thread_count - 1);
    for (int32_t thread = 1; thread < thread_count; ++thread) {
      workers.emplace_back([&, thread] {
        for (int32_t index = thread; index < output_count;
             index += thread_count) {
          score_one(index);
        }
      });
    }
    for (int32_t index = 0; index < output_count; index += thread_count) {
      score_one(index);
    }
    for (auto& worker : workers) worker.join();
  }
  return 0;
}
