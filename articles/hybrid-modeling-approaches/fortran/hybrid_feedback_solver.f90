program hybrid_feedback_solver
  implicit none

  integer, parameter :: n_steps = 80
  integer :: step_index
  real(8) :: demand
  real(8) :: adoption_rate
  real(8) :: growth_rate
  real(8) :: adoption_feedback
  real(8) :: saturation_pressure
  real(8) :: threshold_midpoint
  real(8) :: new_adoption

  demand = 0.30d0
  adoption_rate = 0.0d0
  growth_rate = 0.03d0
  adoption_feedback = 0.25d0
  saturation_pressure = 0.04d0
  threshold_midpoint = 0.55d0

  print '(A)', 'time,demand,adoption_rate,new_adoption'

  do step_index = 1, n_steps
    if (demand > threshold_midpoint) then
      new_adoption = min(1.0d0 - adoption_rate, 0.08d0 + 0.15d0 * (demand - threshold_midpoint))
    else
      new_adoption = 0.01d0 * demand
    end if

    adoption_rate = min(1.0d0, adoption_rate + new_adoption)

    demand = demand + growth_rate * demand + adoption_feedback * adoption_rate - saturation_pressure * demand * demand
    demand = min(max(demand, 0.0d0), 1.5d0)

    print '(I0,A,F12.6,A,F12.6,A,F12.6)', step_index, ',', demand, ',', adoption_rate, ',', new_adoption
  end do

end program hybrid_feedback_solver
