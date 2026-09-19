"""Mathematical tests only. Device/HealthKit/UI acceptance is in the main task book."""
import json
import math
from pathlib import Path
import unittest
from reference_score_v3 import ScoreInput, evaluate, band_for, circular_distance_minutes, circular_median_minutes, round_score


class ReferenceScoreTests(unittest.TestCase):
    def test_24_independent_expected_fixtures(self):
        path = Path(__file__).with_name('SCORE_V3_FIXTURES.json')
        cases = json.loads(path.read_text(encoding='utf-8'))['cases']
        self.assertEqual(len(cases), 24)
        for case in cases:
            with self.subTest(case=case['id']):
                result = evaluate(ScoreInput(**case['input']))
                self.assertEqual(result.score, case['expected']['score'])
                self.assertEqual(result.band, case['expected']['band'])
                if result.components:
                    self.assertAlmostEqual(sum(c.normalized_weight for c in result.components), 1)

    def test_band_boundaries(self):
        for score, expected in [(0,'优先休息'),(49,'优先休息'),(50,'偏低'),(69,'偏低'),(70,'尚可'),(84,'尚可'),(85,'良好'),(100,'良好')]:
            self.assertEqual(band_for(score), expected)

    def test_rounding_is_half_up(self):
        self.assertEqual(round_score(12.5), 13)
        self.assertEqual(round_score(84.5), 85)
        self.assertEqual(round_score(-10), 0)
        self.assertEqual(round_score(110), 100)

    def test_empty_is_not_zero(self):
        self.assertIsNone(evaluate(ScoreInput()).score)
        self.assertEqual(evaluate(ScoreInput(sleep_minutes=0)).score, 0)

    def test_sleep_score_does_not_need_personal_baseline(self):
        for days in [0,1,2]:
            value = evaluate(ScoreInput(sleep_minutes=375, hrv_deviation=0, hrv_days=days, hrv_samples=3, hrv_hours=2))
            self.assertEqual(value.score, 78)
            self.assertEqual([c.name for c in value.components], ['sleep'])

    def test_invalid_dimension_does_not_cancel_other_dimension(self):
        result = evaluate(ScoreInput(sleep_minutes=375, sleep_usable=False, rhr_deviation=0, rhr_days=14))
        self.assertEqual(result.score, 85)
        self.assertEqual([c.name for c in result.components], ['rhr'])

    def test_no_wake_coverage_does_not_imply_perfect_continuity(self):
        result = evaluate(ScoreInput(sleep_minutes=375, awake_minutes=0))
        self.assertNotIn('continuity', result.sleep_subscores)

    def test_circular_clock(self):
        self.assertEqual(circular_distance_minutes(23*60+50, 10), 20)
        self.assertEqual(circular_median_minutes([23*60+50, 0, 10]), 0)
        self.assertIsNone(circular_median_minutes([]))

    def test_sleep_is_monotonic_before_target(self):
        scores=[evaluate(ScoreInput(sleep_minutes=x)).raw_score for x in range(0,481,15)]
        self.assertEqual(scores, sorted(scores))

    def test_adverse_cardio_change_never_improves_score(self):
        scores=[evaluate(ScoreInput(sleep_minutes=375, rhr_deviation=z, rhr_days=14)).raw_score for z in [0,1,2,3,4]]
        self.assertEqual(scores, sorted(scores, reverse=True))

    def test_weights_increase_gradually(self):
        weights=[]
        for days in [3,7,14,28]:
            result=evaluate(ScoreInput(sleep_minutes=375, hrv_deviation=2, hrv_days=days, hrv_samples=3, hrv_hours=2))
            weights.append(next(c.effective_weight for c in result.components if c.name=='hrv'))
        self.assertEqual(weights,sorted(weights))
        self.assertEqual(weights[-1],weights[-2])

    def test_identical_inputs_are_identical(self):
        inp=ScoreInput(sleep_minutes=375,rhr_deviation=1,rhr_days=7)
        self.assertEqual(evaluate(inp), evaluate(inp))

    def test_reject_nonfinite_and_impossible_parameters(self):
        for inp in [ScoreInput(sleep_minutes=math.nan),ScoreInput(rhr_deviation=math.inf),ScoreInput(sleep_goal_minutes=0),ScoreInput(hrv_days=-1),ScoreInput(sleep_minutes=-1)]:
            with self.subTest(inp=inp), self.assertRaises(ValueError):
                evaluate(inp)
        for bad in [-1,101,3.5]:
            with self.assertRaises(ValueError):
                band_for(bad)

    def test_config_matches_the_reference(self):
        p=json.loads(Path(__file__).with_name('SCORE_POLICY_v3.json').read_text(encoding='utf-8'))
        self.assertEqual(p['overallWeights'], {'sleep':0.6,'hrv':0.25,'rhr':0.15})
        self.assertEqual(p['cardio']['minimumHistoryDays'],3)
        self.assertEqual(p['cardio']['fullWeightHistoryDays'],14)

if __name__=='__main__':
    unittest.main(verbosity=2)
