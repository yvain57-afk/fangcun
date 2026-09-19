"""Fangcun v3 mathematical reference — not an iOS implementation or clinical model.

Input features must already be extracted using the task book's source/time policies.
Run tests: python -m unittest -v test_reference_score_v3.py
"""
from __future__ import annotations
from dataclasses import dataclass, asdict
from math import floor, isfinite
from typing import Any

MODEL_VERSION = "fangcun-status-3.0"

@dataclass(frozen=True)
class ScoreInput:
    sleep_minutes: float | None = None
    sleep_goal_minutes: float = 480.0
    sleep_usable: bool = True
    awake_minutes: float | None = None
    awake_coverage_complete: bool = False
    regularity_delta_minutes: float | None = None
    regularity_history_days: int = 0
    hrv_deviation: float | None = None
    hrv_days: int = 0
    hrv_samples: int = 0
    hrv_hours: int = 0
    hrv_usable: bool = True
    rhr_deviation: float | None = None
    rhr_days: int = 0
    rhr_usable: bool = True

@dataclass(frozen=True)
class Component:
    name: str
    score: float
    effective_weight: float
    normalized_weight: float

@dataclass(frozen=True)
class ScoreOutput:
    model_version: str
    raw_score: float | None
    score: int | None
    band: str | None
    components: tuple[Component, ...]
    sleep_subscores: dict[str, float]

    def to_dict(self) -> dict[str, Any]:
        return asdict(self)


def finite(value: float, name: str) -> float:
    if isinstance(value, bool) or not isinstance(value, (int, float)) or not isfinite(value):
        raise ValueError(f"{name} must be a finite number")
    return float(value)


def clamp(value: float, low: float, high: float) -> float:
    return min(high, max(low, value))


def round_score(value: float) -> int:
    return int(floor(clamp(finite(value, "score"), 0, 100) + 0.5))


def band_for(score: int) -> str:
    if type(score) is not int or not 0 <= score <= 100:
        raise ValueError("display score must be an integer in [0, 100]")
    if score >= 85:
        return "良好"
    if score >= 70:
        return "尚可"
    if score >= 50:
        return "偏低"
    return "优先休息"


def circular_distance_minutes(a: float, b: float) -> float:
    delta = abs((finite(a, "a") % 1440) - (finite(b, "b") % 1440))
    return min(delta, 1440 - delta)


def circular_median_minutes(values: list[float]) -> float | None:
    """Choose an observed minimizer; ties use earliest clock minute, deterministically.

    The feature extractor must select prior cycles and compatible time contexts first.
    """
    if not values:
        return None
    candidates = sorted({finite(x, "bedtime") % 1440 for x in values})
    return min(candidates, key=lambda c: (sum(circular_distance_minutes(c, x) for x in values), c))


def cardio_score(z: float) -> float:
    z = finite(z, "deviation")
    return clamp(85 - 15 * max(z, 0) + 5 * min(max(-z, 0), 1), 0, 95)


def validate(inp: ScoreInput) -> None:
    if not 420 <= finite(inp.sleep_goal_minutes, "sleep_goal_minutes") <= 600:
        raise ValueError("sleep goal must be between 420 and 600 minutes")
    for name in ("sleep_minutes", "awake_minutes", "regularity_delta_minutes"):
        value = getattr(inp, name)
        if value is not None and not 0 <= finite(value, name) <= 1440:
            raise ValueError(f"{name} must be in [0,1440] when present")
    for name in ("hrv_deviation", "rhr_deviation"):
        value = getattr(inp, name)
        if value is not None:
            finite(value, name)
    for name in ("regularity_history_days", "hrv_days", "hrv_samples", "hrv_hours", "rhr_days"):
        value = getattr(inp, name)
        if type(value) is not int or value < 0:
            raise ValueError(f"{name} must be a nonnegative integer")


def evaluate(inp: ScoreInput) -> ScoreOutput:
    validate(inp)
    parts: list[tuple[str, float, float]] = []
    sleep_subscores: dict[str, float] = {}
    if inp.sleep_usable and inp.sleep_minutes is not None:
        d = inp.sleep_minutes
        ds = 100 * min(d / inp.sleep_goal_minutes, 1)
        sleep_subscores["duration"] = ds
        sleep_num, sleep_den = 0.70 * ds, 0.70
        if inp.awake_coverage_complete and inp.awake_minutes is not None and d + inp.awake_minutes > 0:
            cs = 100 * d / (d + inp.awake_minutes)
            sleep_subscores["continuity"] = cs
            sleep_num += 0.20 * cs
            sleep_den += 0.20
        if inp.regularity_history_days >= 3 and inp.regularity_delta_minutes is not None:
            rs = 100 * max(0, 1 - inp.regularity_delta_minutes / 120)
            sleep_subscores["regularity"] = rs
            sleep_num += 0.10 * rs
            sleep_den += 0.10
        parts.append(("sleep", sleep_num / sleep_den, 0.60))
    if (inp.hrv_usable and inp.hrv_deviation is not None and inp.hrv_days >= 3
            and inp.hrv_samples >= 1 and inp.hrv_hours >= 1 and inp.hrv_deviation >= -2):
        q = min(1, inp.hrv_days / 14) * min(1, inp.hrv_samples / 3) * min(1, inp.hrv_hours / 2)
        parts.append(("hrv", cardio_score(inp.hrv_deviation), 0.25 * q))
    if inp.rhr_usable and inp.rhr_deviation is not None and inp.rhr_days >= 3:
        q = min(1, inp.rhr_days / 14)
        parts.append(("rhr", cardio_score(inp.rhr_deviation), 0.15 * q))
    den = sum(weight for _, _, weight in parts)
    if den == 0:
        return ScoreOutput(MODEL_VERSION, None, None, None, (), sleep_subscores)
    raw = sum(value * weight for _, value, weight in parts) / den
    # Floating point round trips can put an exact half slightly below the boundary.
    display = round_score(raw + 1e-10)
    components = tuple(Component(name, value, weight, weight / den) for name, value, weight in parts)
    return ScoreOutput(MODEL_VERSION, raw, display, band_for(display), components, sleep_subscores)
