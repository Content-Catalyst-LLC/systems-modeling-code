program feedback_recurrence_solver
  implicit none

  integer, parameter :: n_steps = 90
  integer :: time_index
  integer :: delayed_index

  real(8) :: reinforcing
  real(8) :: balancing
  real(8) :: logistic
  real(8) :: delayed(n_steps)

  real(8) :: target
  real(8) :: reinforcing_rate
  real(8) :: correction
  real(8) :: logistic_rate
  real(8) :: capacity

  integer :: delay_length

  target = 20.0d0
  reinforcing_rate = 0.10d0
  correction = 0.15d0
  logistic_rate = 0.12d0
  capacity = 25.0d0
  delay_length = 5

  reinforcing = 2.0d0
  balancing = 2.0d0
  logistic = 2.0d0
  delayed = 0.0d0
  delayed(1) = 5.0d0

  print '(A)', 'time,reinforcing,balancing,logistic,delayed_balancing'

  do time_index = 1, n_steps
    if (time_index > 1) then
      reinforcing = (1.0d0 + reinforcing_rate) * reinforcing
      balancing = balancing + correction * (target - balancing)
      logistic = logistic + logistic_rate * logistic * (1.0d0 - logistic / capacity)

      delayed_index = time_index - delay_length
      if (delayed_index < 1) then
        delayed_index = 1
      end if

      delayed(time_index) = delayed(time_index - 1) + 0.28d0 * (target - delayed(delayed_index))
    end if

    print '(I0,A,F12.6,A,F12.6,A,F12.6,A,F12.6)', &
      time_index, ',', reinforcing, ',', balancing, ',', logistic, ',', delayed(time_index)
  end do

end program feedback_recurrence_solver
