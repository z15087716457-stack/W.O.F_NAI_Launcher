"""Studio's optional native INT8 ConvRot standalone SeedVR2 adapter.

The owning Windows job controls cancellation. No ComfyUI server, multiprocessing
worker, model download, or application draft is used during inference.
"""
import functools
import json
import importlib.metadata
import os
import re
import sys
from pathlib import Path


def emit(phase, current=0, total=1):
    print(json.dumps({"phase": phase, "current": current, "total": total}), flush=True)


def main():
    source = Path(sys.argv[1]).resolve(strict=True)
    options = sys.argv[2:]
    probe = options == ["--probe"]
    sys.path.insert(0, str(source))
    sys.argv = [str(source / "inference_cli.py"), *([] if probe else options)]
    os.environ["HF_HUB_OFFLINE"] = "1"
    os.environ["TRANSFORMERS_OFFLINE"] = "1"
    os.environ["HF_HUB_DISABLE_TELEMETRY"] = "1"
    os.environ["PYTHONIOENCODING"] = "utf-8"
    if sys.version_info[:3] != (3, 12, 11):
        raise RuntimeError("python_version_mismatch")
    requirements = Path(__file__).with_name("requirements.lock").read_text()
    for name, version in re.findall(r"^([A-Za-z0-9_.-]+)==([^\s\\]+)", requirements, re.M):
        if importlib.metadata.version(name) != version:
            raise RuntimeError("runtime_version_mismatch:" + name)
    emit("preparing")
    import torch
    if not torch.cuda.is_available():
        print(json.dumps({"error": "no_cuda"}), file=sys.stderr, flush=True)
        return 12
    import native_int8
    native_int8.probe()
    native_int8.install()
    import inference_cli as cli
    if probe:
        print(json.dumps({"available": True, "python": sys.version.split()[0],
                          "torch": torch.__version__, "cuda": torch.version.cuda,
                          "device": torch.cuda.get_device_name(0)}), flush=True)
        return 0
    args = cli.parse_arguments()
    if cli.get_input_type(args.input) != "image":
        raise ValueError("image_required")
    # This path directly calls the pipeline in this process; the CLI's GPU
    # multiprocessing entry point is deliberately not invoked.
    args.cache_dit = True
    args.cache_vae = True
    args.cuda_device = "0"
    if not Path(args.model_dir).is_absolute():
        raise ValueError("absolute_model_path_required")
    for name in (args.dit_model, cli.DEFAULT_VAE):
        if not (Path(args.model_dir) / name).is_file():
            raise ValueError("model_missing")
    # No fallback network request is permitted while working on a user image.
    import requests
    def offline_request(*args, **kwargs):
        raise RuntimeError("offline_inference")
    requests.sessions.Session.request = offline_request

    def instrument(name, phase):
        original = getattr(cli, name)
        @functools.wraps(original)
        def wrapped(*positional, **kwargs):
            emit(phase)
            def progress(current, total, frames, phase_name):
                emit(phase, current, total)
            kwargs["progress_callback"] = progress
            result = original(*positional, **kwargs)
            emit(phase, 1, 1)
            return result
        setattr(cli, name, wrapped)
    instrument("encode_all_batches", "encoding")
    instrument("upscale_all_batches", "inference")
    instrument("decode_all_batches", "decoding")
    instrument("postprocess_all_batches", "resizing")
    count = cli.process_single_file(args.input, args, ["0"], args.output,
                                    runner_cache={})
    if count != 1 or not Path(args.output).is_file():
        raise RuntimeError("output_missing")
    emit("complete", 1, 1)
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception as error:
        if type(error).__name__ == "NativeInt8Unavailable":
            print(json.dumps({"error": "no_int8", "detail": str(error)}),
                  file=sys.stderr, flush=True)
            sys.exit(13)
        # Keep model/runtime errors in bounded diagnostics for the app.
        print(json.dumps({"error": type(error).__name__, "detail": str(error)}),
              file=sys.stderr, flush=True)
        sys.exit(11)
