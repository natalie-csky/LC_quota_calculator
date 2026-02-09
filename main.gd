extends Control

const DAYS := 3 as int

@export var label: Label
@export var avg_needed_label: Label

@export var amount_quotas := 20 as int

@export_group("Quota Settings")
@export var starting_quota := 130 as int
@export var base_increase := 100
@export var steepness := 16.0 as float
@export var curve_multiplier := 1.0 as float

var SAMPLE_RUNS := 300000 as int


## higher luck:
## - lowers the quota
## - reduces the randomization (if luck were exactly 1.0, there is no randomness anymore)
var total_luck := 0.0

# silly global value
var times_fulfilled := 0

## the more values this curve has hard-coded in, the higher the precision of the calculation
##
## best would be to have access to the actual function that calculates the curve
## for perfect precision, but i dunno where to get it
var randomizer_curve := {
	0.0 : -0.5,
	0.05: -0.27,
	0.1: -0.125,
	0.2: -0.0875,
	0.3: -0.05,
	0.4: -0.0125,
	0.45: 0.005,
	0.5: 0.0125,
	0.6: 0.05,
	0.7: 0.0875,
	0.75: 0.095,
	0.8: 0.12,
	0.9: 0.17,
	0.95: 0.27,
	1.0: 0.5
} as Dictionary[float, float]


func _on_button_pressed() -> void:
	label.text = ""
	avg_needed_label.text = ""

	var runs_quotas := _do_runs()

	var average_run_quotas: Array[int]
	average_run_quotas.resize(amount_quotas)

	for current_quota_i in range(amount_quotas):
		for run_quotas in runs_quotas:
			average_run_quotas[current_quota_i] += run_quotas[current_quota_i]
		average_run_quotas[current_quota_i] /= runs_quotas.size()

	for i in range(amount_quotas):
		#label.text = label.text + str(i + 1) + ": " + str(average_run_quotas[i]) + '\n'
		label.text = label.text + str(average_run_quotas[i]) + '\n'

	var total := 0.0

	for i in range(amount_quotas):
		total += average_run_quotas[i]
		var avg_needed = total / ((i + 1) * float(DAYS))
		avg_needed_label.text = avg_needed_label.text + str(avg_needed).pad_decimals(0) + '\n'



func _do_runs() -> Array:
	var runs_quotas := []
	var quota := 0
	var quotas := []

	for _j in range(SAMPLE_RUNS):
		times_fulfilled = 0
		quota = 0
		quotas.resize(0)

		for i in range(amount_quotas):
			if i == 0:
				quota = starting_quota
				quotas.append(quota)
				continue

			times_fulfilled += 1
			quota += int(_calc_and_get_increase())
			quotas.append(quota)

		runs_quotas.append(quotas)
	return runs_quotas


func _calc_and_get_increase() -> float:
	return (base_increase * (curve_multiplier + pow(times_fulfilled, 2.0) / steepness)
			* (randomizer_curve[_approx(randf_range(0.0, 1.0) * absf(total_luck - 1))] + 1))


## find closest point on randomizer_curve
func _approx(input: float) -> float:
	var f = func(prev: float, curr: float): return curr if absf(prev - curr) < absf(prev - input) else prev
	return randomizer_curve.keys().reduce(f)


func _on_quotas_done_text_changed(new_text: String) -> void:
	if new_text.is_valid_int():
		times_fulfilled = int(new_text)


func _on_total_luck_text_changed(new_text: String) -> void:
	if new_text.is_valid_float():
		total_luck = float(new_text)


func _on_amount_runs_text_changed(new_text: String) -> void:
	if new_text.is_valid_int():
		SAMPLE_RUNS = int(new_text)
