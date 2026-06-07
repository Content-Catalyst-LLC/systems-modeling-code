program iam_recurrence_solver
  implicit none
  integer :: year
  real(8) :: output_value, emissions_intensity_value, mitigation_rate_value
  real(8) :: atmospheric_pressure_value, temperature_proxy_value, emissions_value
  real(8) :: damages_value, mitigation_cost_value, consumption_proxy_value, welfare_value
  output_value = 100.0d0
  emissions_intensity_value = 0.42d0
  mitigation_rate_value = 0.06d0
  atmospheric_pressure_value = 1.0d0
  temperature_proxy_value = 1.2d0
  print '(A)', 'year,output,emissions_intensity,mitigation_rate,emissions,atmospheric_pressure,temperature_proxy,damages,mitigation_cost,consumption_proxy,discounted_welfare_proxy'
  do year = 2025, 2100, 5
    if (year > 2025) then
      output_value = output_value * (1.012d0 ** 5)
      emissions_intensity_value = max(0.02d0, emissions_intensity_value * ((1.0d0 - 0.012d0) ** 5))
      mitigation_rate_value = min(0.95d0, mitigation_rate_value + 0.025d0)
    end if
    emissions_value = output_value * emissions_intensity_value * (1.0d0 - mitigation_rate_value)
    if (year > 2025) then
      atmospheric_pressure_value = max(0.0d0, atmospheric_pressure_value + 0.012d0 * emissions_value - 0.010d0 * atmospheric_pressure_value)
      temperature_proxy_value = max(0.0d0, temperature_proxy_value + 0.030d0 * atmospheric_pressure_value - 0.012d0 * temperature_proxy_value)
    end if
    damages_value = 0.010d0 * temperature_proxy_value ** 2 * output_value
    mitigation_cost_value = 0.040d0 * mitigation_rate_value ** 2 * output_value
    consumption_proxy_value = max(0.0d0, output_value - damages_value - mitigation_cost_value)
    welfare_value = log(consumption_proxy_value + 1.0d0) / (1.015d0 ** (year - 2025))
    print '(I0,A,F12.6,A,F12.6,A,F12.6,A,F12.6,A,F12.6,A,F12.6,A,F12.6,A,F12.6,A,F12.6,A,F12.6)', year, ',', output_value, ',', emissions_intensity_value, ',', mitigation_rate_value, ',', emissions_value, ',', atmospheric_pressure_value, ',', temperature_proxy_value, ',', damages_value, ',', mitigation_cost_value, ',', consumption_proxy_value, ',', welfare_value
  end do
end program iam_recurrence_solver
