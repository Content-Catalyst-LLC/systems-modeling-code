program environmental_recurrence_solver
  implicit none

  integer, parameter :: n_steps = 120
  integer :: step_index
  real(8) :: stock_value
  real(8) :: carrying_capacity
  real(8) :: growth_rate
  real(8) :: extraction_rate
  real(8) :: restoration_rate
  real(8) :: regeneration_value
  real(8) :: extraction_value
  real(8) :: restoration_value
  real(8) :: disturbance_value
  real(8) :: resilience_index

  stock_value = 70.0d0
  carrying_capacity = 100.0d0
  growth_rate = 0.065d0
  extraction_rate = 0.040d0
  restoration_rate = 0.010d0

  print '(A)', 'time,stock,regeneration,extraction,restoration,disturbance,resilience_index'

  do step_index = 1, n_steps
    regeneration_value = growth_rate * stock_value * (1.0d0 - stock_value / carrying_capacity)
    extraction_value = extraction_rate * stock_value
    restoration_value = restoration_rate * (carrying_capacity - stock_value)

    if (step_index == 65) then
      disturbance_value = 12.0d0
    else
      disturbance_value = 0.0d0
    end if

    stock_value = stock_value + regeneration_value - extraction_value
    stock_value = stock_value + restoration_value - disturbance_value
    stock_value = max(0.0d0, min(carrying_capacity, stock_value))
    resilience_index = stock_value / carrying_capacity

    print '(I0,A,F12.6,A,F12.6,A,F12.6,A,F12.6,A,F12.6,A,F12.6)', &
      step_index, ',', stock_value, ',', regeneration_value, ',', extraction_value, ',', &
      restoration_value, ',', disturbance_value, ',', resilience_index
  end do

end program environmental_recurrence_solver
