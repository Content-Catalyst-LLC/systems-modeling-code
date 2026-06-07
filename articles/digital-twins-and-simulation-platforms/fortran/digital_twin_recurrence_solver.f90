program digital_twin_recurrence_solver
  implicit none

  integer, parameter :: steps = 120
  integer :: t
  real(8) :: true_state
  real(8) :: observed_state
  real(8) :: twin_state
  real(8) :: prediction
  real(8) :: residual
  real(8) :: drift
  real(8) :: shock
  integer :: anomaly_flag
  integer :: intervention_flag

  true_state = 50.0d0
  observed_state = true_state
  twin_state = observed_state

  print '(A)', 'time,true_state,observed_state,twin_state,residual,anomaly_flag,intervention_flag'
  print '(I0,A,F12.6,A,F12.6,A,F12.6,A,F12.6,A,I0,A,I0)', 0, ',', true_state, ',', observed_state, ',', twin_state, ',', 0.0d0, ',', 0, ',', 0

  do t = 1, steps - 1
    drift = 0.15d0 * sin(dble(t) / 12.0d0)

    if (t == 35 .or. t == 80 .or. t == 105) then
      shock = 4.0d0
    else
      shock = 0.0d0
    end if

    true_state = 0.95d0 * true_state + drift + shock + sin(dble(t) * 1.61803398875d0) * 0.60d0
    observed_state = true_state + sin(dble(t + 200) * 1.61803398875d0) * 1.80d0

    prediction = 0.95d0 * twin_state + drift
    residual = observed_state - prediction

    if (abs(residual) > 3.50d0) then
      anomaly_flag = 1
    else
      anomaly_flag = 0
    end if

    if (residual > 3.50d0) then
      intervention_flag = 1
      prediction = prediction - 1.0d0
    else
      intervention_flag = 0
    end if

    twin_state = prediction + 0.35d0 * residual

    print '(I0,A,F12.6,A,F12.6,A,F12.6,A,F12.6,A,I0,A,I0)', &
      t, ',', true_state, ',', observed_state, ',', twin_state, ',', residual, ',', anomaly_flag, ',', intervention_flag
  end do

end program digital_twin_recurrence_solver
