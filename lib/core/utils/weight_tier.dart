/// Shared emphasis boundaries for the editor and image viewer.
enum WeightTier { negative, bottom, low, none, high, top }

WeightTier weightTier(double weight) {
  if (weight < 0) return WeightTier.negative;
  if (weight < .5) return WeightTier.bottom;
  if (weight < 1) return WeightTier.low;
  if (weight > 2) return WeightTier.top;
  if (weight > 1) return WeightTier.high;
  return WeightTier.none;
}
