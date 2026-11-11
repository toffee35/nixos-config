"""Waybar JSON from the running NVIDIA driver's NVML, without nvidia-smi."""

import ctypes as c
import html
import json
from pathlib import Path
import subprocess


def nvml_path():
    active = Path("/run/opengl-driver/lib/libnvidia-ml.so.1")
    version = Path("/sys/module/nvidia/version").read_text().strip()
    if active.resolve().name == f"libnvidia-ml.so.{version}":
        return str(active)
    # nixos-rebuild switch updates /run/opengl-driver without replacing the
    # running kernel module. The booted generation remains a GC root and
    # contains the matching userspace driver until the next reboot.
    paths = subprocess.run(
        ["/run/current-system/sw/bin/nix-store", "--query", "--requisites", "/run/booted-system"],
        capture_output=True, text=True, check=True, timeout=10,
    ).stdout.splitlines()
    for path in paths:
        if Path(path).name.endswith(f"-nvidia-x11-{version}"):
            library = Path(path) / "lib" / f"libnvidia-ml.so.{version}"
            if library.is_file():
                return str(library)
    raise RuntimeError(f"NVML matching loaded NVIDIA {version} not found; reboot required")


class Memory(c.Structure):
    _fields_ = [(name, c.c_ulonglong) for name in ("total", "free", "used")]


class Utilization(c.Structure):
    _fields_ = [("gpu", c.c_uint), ("memory", c.c_uint)]


def read_gpu():
    nvml = c.CDLL(nvml_path())

    def bind(name, *args):
        fn = getattr(nvml, name)
        fn.argtypes = list(args)
        fn.restype = c.c_int
        return fn

    init = bind("nvmlInit_v2")
    shutdown = bind("nvmlShutdown")
    device = bind("nvmlDeviceGetHandleByIndex_v2", c.c_uint, c.POINTER(c.c_void_p))
    name = bind("nvmlDeviceGetName", c.c_void_p, c.POINTER(c.c_char), c.c_uint)
    temperature = bind("nvmlDeviceGetTemperature", c.c_void_p, c.c_uint, c.POINTER(c.c_uint))
    utilization = bind("nvmlDeviceGetUtilizationRates", c.c_void_p, c.POINTER(Utilization))
    memory = bind("nvmlDeviceGetMemoryInfo", c.c_void_p, c.POINTER(Memory))
    nvml.nvmlErrorString.argtypes = [c.c_int]
    nvml.nvmlErrorString.restype = c.c_char_p

    def check(code):
        if code:
            raise RuntimeError(nvml.nvmlErrorString(code).decode(errors="replace"))

    check(init())
    try:
        handle = c.c_void_p()
        check(device(0, c.byref(handle)))
        gpu_name = c.create_string_buffer(256)
        temp = c.c_uint()
        util = Utilization()
        mem = Memory()
        check(name(handle, gpu_name, len(gpu_name)))
        check(temperature(handle, 0, c.byref(temp)))
        check(utilization(handle, c.byref(util)))
        check(memory(handle, c.byref(mem)))
        if not mem.total:
            raise RuntimeError("NVML returned zero total VRAM")
        used, total = mem.used / 1024**3, mem.total / 1024**3
        return {
            "text": f"󰢮 {temp.value}°C {util.gpu}% {used:.1f}/{total:.1f}G",
            "tooltip": (
                f"{html.escape(gpu_name.value.decode(errors='replace'))}\n"
                f"GPU: {util.gpu}% · {temp.value}°C\n"
                f"VRAM: {mem.used / 1024**2:.0f} / {mem.total / 1024**2:.0f} MiB"
                f" ({100 * mem.used / mem.total:.1f}%)"
            ),
            "class": "gpu",
            "percentage": round(100 * mem.used / mem.total),
        }
    finally:
        shutdown()


def main():
    try:
        result = read_gpu()
    except (OSError, RuntimeError, AttributeError, subprocess.SubprocessError) as error:
        # Keep a visible status and retry on the next interval, instead of
        # silently disappearing when the driver is temporarily unavailable.
        result = {
            "text": "󰢮 N/A",
            "tooltip": f"NVIDIA NVML: {html.escape(str(error))}",
            "class": "unavailable",
        }
    print(json.dumps(result, ensure_ascii=False))


if __name__ == "__main__":
    main()
