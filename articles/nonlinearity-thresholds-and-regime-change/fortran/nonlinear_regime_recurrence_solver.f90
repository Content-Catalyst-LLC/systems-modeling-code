program nonlinear_regime_recurrence_solver
  implicit none

  integer, parameter :: n_steps = 140
  integer :: time_index
  real(8) :: system_state
  real(8) :: pressure
  real(8) :: collapse_threshold
  real(8) :: recovery_threshold
  real(8) :: pressure_growth
  real(8) :: recovery_effort
  real(8) :: damage_flow
  real(8) :: recovery_flow
  real(8) :: net_flow
  integer :: intervention_time
  character(len=16) :: regime

  system_state = 82.0d0
  pressure = 20.0d0
  collapse_threshold = 70.0d0
  recovery_threshold = 45.0d0
  pressure_growth = 0.85d0
  recovery_effort = 1.20d0
  intervention_time = 85
  regime = 'stable'

  print '(A)', 'time,system_state,pressure,regime,damage_flow,recovery_flow,net_flow'

  do time_index = 1, n_steps
    damage_flow = 0.0d0
    recovery_flow = 0.0d0
    net_flow = 0.0d0

    if (time_index > 1) then
      pressure = pressure + pressure_growth

      if (time_index >= intervention_time) then
        pressure = max(0.0d0, pressure - recovery_effort)
      end if

      if (trim(regime) == 'stable' .and. pressure >= collapse_threshold) then
        regime = 'degraded'
      else if (trim(regime) == 'degraded' .and. pressure <= recovery_threshold) then
        regime = 'stable'
      end if

      if (trim(regime) == 'stable') then
        damage_flow = 0.05d0 * pressure + 0.002d0 * pressure * pressure
        recovery_flow = 2.6d0
      else
        damage_flow = 0.09d0 * pressure + 0.006d0 * pressure * pressure + 1.8d0
        recovery_flow = 0.8d0 + 0.03d0 * system_state
      end if

      net_flow = recovery_flow - damage_flow
      system_state = min(100.0d0, max(0.0d0, system_state + net_flow))
    end if

    print '(I0,A,F12.6,A,F12.6,A,A,A,F12.6,A,F12.6,A,F12.6)', &
      time_index, ',', system_state, ',', pressure, ',', trim(regime), ',', damage_flow, ',', recovery_flow, ',', net_flow
  end do

end program nonlinear_regime_recurrence_solver
