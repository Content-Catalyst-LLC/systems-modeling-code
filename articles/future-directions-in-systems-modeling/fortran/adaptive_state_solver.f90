program adaptive_state_solver
  implicit none

  integer, parameter :: n = 24
  integer :: t, intervention
  real(8) :: true_state, estimate, observed, drift
  real(8) :: shock, prediction, residual

  true_state = 12.0d0
  estimate = 12.0d0
  observed = 12.0d0
  drift = 0.0d0

  print '(A)', 'time,true_state,observed_state,estimated_state,residual,drift_indicator,intervention_flag'

  do t = 0, n - 1
    if (t == 8 .or. t == 16) then
      shock = 4.0d0
    else
      shock = 0.0d0
    end if

    true_state = 0.93d0 * true_state + 0.3d0 * sin(dble(t) / 10.0d0) + shock
    observed = true_state + 0.4d0 * sin(dble(t) / 3.0d0)

    prediction = 0.93d0 * estimate + 0.3d0 * sin(dble(t) / 10.0d0)
    residual = observed - prediction

    if (abs(residual) > 3.0d0) then
      intervention = 1
      prediction = prediction + 0.25d0 * residual
    else
      intervention = 0
    end if

    estimate = 0.70d0 * prediction + 0.30d0 * observed
    drift = 0.80d0 * drift + 0.20d0 * abs(observed - estimate)

    print '(I0,",",F10.6,",",F10.6,",",F10.6,",",F10.6,",",F10.6,",",I0)', &
      t, true_state, observed, estimate, residual, drift, intervention
  end do

end program adaptive_state_solver
