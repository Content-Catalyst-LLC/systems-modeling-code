program scenario_recurrence_solver
  implicit none

  integer, parameter :: n_steps = 80
  integer :: time_index

  real(8) :: state
  real(8) :: capacity_buffer
  real(8) :: stress_index
  real(8) :: growth
  real(8) :: policy_drag
  real(8) :: shock_size
  real(8) :: shock_effect
  real(8) :: resilience_investment
  integer :: shock_time

  growth = 0.045d0
  policy_drag = 0.012d0
  shock_time = 42
  shock_size = 22.0d0
  resilience_investment = 8.0d0

  state = 20.0d0
  capacity_buffer = 5.0d0 + resilience_investment
  stress_index = state / capacity_buffer

  print '(A)', 'time,state,capacity_buffer,stress_index,growth,policy_drag,shock_size'

  do time_index = 1, n_steps
    shock_effect = 0.0d0

    if (time_index == shock_time) then
      shock_effect = shock_size / max(1.0d0, capacity_buffer)
    end if

    state = state + growth * state - policy_drag * state - shock_effect
    state = max(state, 0.0d0)

    capacity_buffer = capacity_buffer + 0.04d0 * resilience_investment - 0.01d0 * max(state - 40.0d0, 0.0d0)
    capacity_buffer = max(capacity_buffer, 1.0d0)

    stress_index = state / capacity_buffer

    print '(I0,A,F12.6,A,F12.6,A,F12.6,A,F12.6,A,F12.6,A,F12.6)', &
      time_index, ',', state, ',', capacity_buffer, ',', stress_index, ',', growth, ',', policy_drag, ',', shock_size
  end do

end program scenario_recurrence_solver
