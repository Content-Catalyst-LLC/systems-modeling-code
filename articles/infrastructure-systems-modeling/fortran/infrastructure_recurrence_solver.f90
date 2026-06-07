program infrastructure_recurrence_solver
  implicit none

  integer, parameter :: n_steps = 80
  integer :: time_index
  real(8) :: power_value
  real(8) :: communications_value
  real(8) :: water_value
  real(8) :: transport_value
  real(8) :: composite_service_value
  real(8) :: unmet_service_value
  integer :: shock_active_value

  power_value = 1.0d0
  communications_value = 1.0d0
  water_value = 1.0d0
  transport_value = 1.0d0

  print '(A)', 'time,power,communications,water,transport,composite_service,unmet_service,shock_active'

  do time_index = 0, n_steps - 1
    if (time_index >= 20 .and. time_index <= 36) then
      power_value = max(0.45d0, power_value - 0.035d0)
      shock_active_value = 1
    else if (time_index > 36) then
      power_value = min(1.0d0, power_value + 0.025d0)
      shock_active_value = 0
    else
      power_value = 1.0d0
      shock_active_value = 0
    end if

    communications_value = max(0.40d0, 0.72d0 * power_value + 0.28d0 * communications_value)
    water_value = max(0.35d0, 0.55d0 * power_value + 0.25d0 * communications_value + 0.20d0 * water_value)
    transport_value = max(0.35d0, 0.30d0 * power_value + 0.25d0 * communications_value + 0.45d0 * transport_value)

    composite_service_value = (power_value + communications_value + water_value + transport_value) / 4.0d0
    unmet_service_value = 1.0d0 - composite_service_value

    print '(I0,A,F10.6,A,F10.6,A,F10.6,A,F10.6,A,F10.6,A,F10.6,A,I0)', &
      time_index, ',', power_value, ',', communications_value, ',', water_value, ',', &
      transport_value, ',', composite_service_value, ',', unmet_service_value, ',', shock_active_value
  end do

end program infrastructure_recurrence_solver
