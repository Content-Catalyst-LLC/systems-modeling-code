program stock_flow_feedback
  implicit none

  integer, parameter :: steps = 140
  integer :: t
  real, dimension(steps) :: stock_a, stock_b
  real :: growth_a_rate, growth_b_rate, b_to_a_pressure, a_to_b_support
  real :: b_balancing_rate, target_b, reinforcing_a, pressure_from_b
  real :: reinforcing_b, support_from_a, balancing_b

  stock_a = 0.0
  stock_b = 0.0

  stock_a(1) = 20.0
  stock_b(1) = 10.0

  growth_a_rate = 0.06
  growth_b_rate = 0.04
  b_to_a_pressure = 0.02
  a_to_b_support = 0.04
  b_balancing_rate = 0.03
  target_b = 45.0

  do t = 2, steps
    reinforcing_a = growth_a_rate * stock_a(t - 1)
    pressure_from_b = -b_to_a_pressure * stock_b(t - 1)

    reinforcing_b = growth_b_rate * stock_b(t - 1)
    support_from_a = a_to_b_support * stock_a(t - 1)
    balancing_b = b_balancing_rate * max(stock_b(t - 1) - target_b, 0.0)

    stock_a(t) = stock_a(t - 1) + reinforcing_a + pressure_from_b
    stock_b(t) = stock_b(t - 1) + reinforcing_b + support_from_a - balancing_b
  end do

  print *, "Final stock A:", stock_a(steps)
  print *, "Final stock B:", stock_b(steps)

end program stock_flow_feedback
