program model_comparison_solver
  implicit none

  integer, parameter :: n_steps = 90
  integer :: time_index
  real(8) :: exponential_state
  real(8) :: logistic_state
  real(8) :: managed_state

  exponential_state = 12.0d0
  logistic_state = 12.0d0
  managed_state = 12.0d0

  print '(A)', 'time,exponential,logistic,managed_logistic'

  do time_index = 1, n_steps
    if (time_index > 1) then
      exponential_state = max(0.0d0, exponential_state + 0.060d0 * exponential_state)

      logistic_state = max(0.0d0, logistic_state + &
        0.085d0 * logistic_state * (1.0d0 - logistic_state / 130.0d0))

      managed_state = max(0.0d0, managed_state + &
        0.085d0 * managed_state * (1.0d0 - managed_state / 130.0d0) - &
        0.012d0 * managed_state)
    end if

    print '(I0,A,F12.6,A,F12.6,A,F12.6)', &
      time_index, ',', exponential_state, ',', logistic_state, ',', managed_state
  end do

end program model_comparison_solver
