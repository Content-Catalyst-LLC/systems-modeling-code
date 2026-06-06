program coupled_stock_recurrence_model
  implicit none

  integer, parameter :: n_steps = 140
  integer :: t
  real(8) :: stock_a, stock_b, pressure
  real(8) :: growth_a, coupling_ab, growth_b, coupling_ba
  real(8) :: balancing_b, target_b, shock
  real(8) :: reinforcing_a, pressure_from_b, reinforcing_b
  real(8) :: support_from_a, correction_b, pressure_feedback

  stock_a = 24.0d0
  stock_b = 18.0d0
  pressure = 30.0d0

  growth_a = 0.045d0
  coupling_ab = 0.018d0
  growth_b = 0.032d0
  coupling_ba = 0.041d0
  balancing_b = 0.026d0
  target_b = 55.0d0

  print '(A)', 'time,stock_a,stock_b,pressure,total_state'

  do t = 1, n_steps
    print '(I0,A,F10.6,A,F10.6,A,F10.6,A,F10.6)', t, ',', stock_a, ',', stock_b, ',', pressure, ',', stock_a + stock_b

    if (t == 75) then
      shock = -12.0d0
    else
      shock = 0.0d0
    end if

    reinforcing_a = growth_a * stock_a
    pressure_from_b = -coupling_ab * stock_b
    reinforcing_b = growth_b * stock_b
    support_from_a = coupling_ba * stock_a
    correction_b = balancing_b * max(stock_b - target_b, 0.0d0)
    pressure_feedback = 0.018d0 * max(stock_b - target_b, 0.0d0) + 0.012d0 * max(stock_a - 70.0d0, 0.0d0)

    stock_a = max(0.0d0, stock_a + reinforcing_a + pressure_from_b + shock - 0.018d0 * pressure)
    stock_b = max(0.0d0, stock_b + reinforcing_b + support_from_a - correction_b - 0.010d0 * pressure)
    pressure = max(0.0d0, pressure + pressure_feedback - 0.045d0 * pressure)
  end do

end program coupled_stock_recurrence_model
