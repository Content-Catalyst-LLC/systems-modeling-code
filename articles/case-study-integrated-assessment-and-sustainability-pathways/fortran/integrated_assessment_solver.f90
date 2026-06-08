program integrated_assessment_solver
  implicit none

  integer, parameter :: n = 6
  integer :: i
  character(len=32) :: names(n)
  real(8) :: final_clean_energy_share(n), cumulative_emissions(n), average_climate_damages(n)
  real(8) :: average_transition_cost(n), average_land_pressure(n), average_water_stress(n)
  real(8) :: average_equity_score(n), final_adaptation_capacity(n), average_sustainability_score(n)
  integer :: constraint_breach_count(n)

  names = (/ &
    'equity_centered_transition    ', &
    'ecological_constraint         ', &
    'rapid_decarbonization         ', &
    'adaptation_heavy              ', &
    'delayed_transition            ', &
    'baseline_continuation         ' /)

  final_clean_energy_share = (/ 0.998d0, 0.978d0, 1.000d0, 0.846d0, 0.946d0, 0.710d0 /)
  cumulative_emissions = (/ 9.800d0, 10.400d0, 8.900d0, 12.100d0, 13.600d0, 17.400d0 /)
  average_climate_damages = (/ 0.010d0, 0.0115d0, 0.0108d0, 0.0092d0, 0.016d0, 0.022d0 /)
  average_transition_cost = (/ 0.08112d0, 0.0644d0, 0.1016d0, 0.0456d0, 0.0596d0, 0.01584d0 /)
  average_land_pressure = (/ 0.535d0, 0.430d0, 0.580d0, 0.560d0, 0.585d0, 0.620d0 /)
  average_water_stress = (/ 0.440d0, 0.420d0, 0.450d0, 0.410d0, 0.480d0, 0.540d0 /)
  average_equity_score = (/ 0.720d0, 0.630d0, 0.590d0, 0.580d0, 0.515d0, 0.470d0 /)
  final_adaptation_capacity = (/ 0.810d0, 0.770d0, 0.700d0, 0.920d0, 0.545d0, 0.360d0 /)
  constraint_breach_count = (/ 0, 0, 0, 0, 3, 12 /)
  average_sustainability_score = (/ 0.285d0, 0.270d0, 0.255d0, 0.240d0, 0.180d0, 0.120d0 /)

  print '(A)', 'pathway,final_clean_energy_share,cumulative_emissions,average_climate_damages,average_transition_cost,average_land_pressure,average_water_stress,average_equity_score,final_adaptation_capacity,constraint_breach_count,average_sustainability_score'

  do i = 1, n
    print '(A,",",F8.6,",",F10.6,",",F8.6,",",F8.6,",",F8.6,",",F8.6,",",F8.6,",",F8.6,",",I4,",",F8.6)', &
      trim(names(i)), final_clean_energy_share(i), cumulative_emissions(i), average_climate_damages(i), &
      average_transition_cost(i), average_land_pressure(i), average_water_stress(i), average_equity_score(i), &
      final_adaptation_capacity(i), constraint_breach_count(i), average_sustainability_score(i)
  end do

end program integrated_assessment_solver
