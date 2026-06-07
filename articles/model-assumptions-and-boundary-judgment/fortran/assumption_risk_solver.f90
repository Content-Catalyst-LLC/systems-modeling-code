program assumption_risk_solver
  implicit none

  integer, parameter :: n = 9
  integer :: i
  character(len=4) :: ids(n)
  character(len=20) :: categories(n)
  real(8) :: uncertainty(n)
  real(8) :: sensitivity(n)
  real(8) :: consequence(n)
  real(8) :: risk_score

  ids = (/ 'A1  ', 'A2  ', 'A3  ', 'A4  ', 'A5  ', 'A6  ', 'A7  ', 'A8  ', 'A9  ' /)

  categories = (/ &
    'boundary            ', &
    'data                ', &
    'parameter           ', &
    'behavioral          ', &
    'scenario            ', &
    'normative           ', &
    'scale               ', &
    'causal              ', &
    'measurement         ' /)

  uncertainty = (/ 0.80d0, 0.55d0, 0.40d0, 0.70d0, 0.65d0, 0.75d0, 0.50d0, 0.45d0, 0.70d0 /)
  sensitivity = (/ 0.75d0, 0.60d0, 0.85d0, 0.50d0, 0.80d0, 0.90d0, 0.65d0, 0.80d0, 0.70d0 /)
  consequence = (/ 0.90d0, 0.70d0, 0.65d0, 0.60d0, 0.85d0, 0.95d0, 0.75d0, 0.80d0, 0.85d0 /)

  print '(A)', 'assumption_id,category,uncertainty,sensitivity,consequence,risk_score'

  do i = 1, n
    risk_score = uncertainty(i) * sensitivity(i) * consequence(i)

    print '(A,",",A,",",F8.6,",",F8.6,",",F8.6,",",F8.6)', &
      trim(ids(i)), trim(categories(i)), uncertainty(i), sensitivity(i), consequence(i), risk_score
  end do

end program assumption_risk_solver
