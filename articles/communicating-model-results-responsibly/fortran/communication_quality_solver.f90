program communication_quality_solver
  implicit none

  integer, parameter :: n = 6
  integer :: i
  character(len=4) :: ids(n)
  character(len=16) :: types(n)
  real(8) :: lower_bound(n), upper_bound(n)
  real(8) :: assumption(n), uncertainty(n), boundary(n), misuse(n)
  real(8) :: width, quality

  ids = (/ 'R1  ', 'R2  ', 'R3  ', 'R4  ', 'R5  ', 'R6  ' /)
  types = (/ &
    'scenario        ', &
    'forecast        ', &
    'ranking         ', &
    'map             ', &
    'optimization    ', &
    'dashboard       ' /)

  lower_bound = (/ 0.55d0, 9000.0d0, 0.75d0, 0.40d0, 0.80d0, 0.62d0 /)
  upper_bound = (/ 0.88d0, 16000.0d0, 0.89d0, 0.82d0, 0.96d0, 0.86d0 /)
  assumption = (/ 0.80d0, 0.60d0, 0.70d0, 0.45d0, 0.65d0, 0.55d0 /)
  uncertainty = (/ 0.85d0, 0.75d0, 0.55d0, 0.40d0, 0.60d0, 0.50d0 /)
  boundary = (/ 0.70d0, 0.55d0, 0.65d0, 0.50d0, 0.60d0, 0.55d0 /)
  misuse = (/ 0.75d0, 0.60d0, 0.45d0, 0.40d0, 0.55d0, 0.35d0 /)

  print '(A)', 'result_id,result_type,uncertainty_width,communication_quality_score'

  do i = 1, n
    width = upper_bound(i) - lower_bound(i)
    quality = 0.30d0 * assumption(i) + 0.30d0 * uncertainty(i) + 0.20d0 * boundary(i) + 0.20d0 * misuse(i)

    print '(A,",",A,",",F12.6,",",F8.6)', trim(ids(i)), trim(types(i)), width, quality
  end do

end program communication_quality_solver
