program geospatial_grid_solver
  implicit none

  integer, parameter :: grid_size = 25
  integer :: x, y
  real(8) :: center
  real(8) :: d_center
  real(8) :: d_river
  real(8) :: population
  real(8) :: hazard
  real(8) :: vulnerability
  real(8) :: risk_score
  real(8) :: accessibility
  real(8) :: service_gap_score

  center = (dble(grid_size) + 1.0d0) / 2.0d0

  print '(A)', 'x,y,population,hazard,vulnerability,risk_score,accessibility,service_gap_score'

  do x = 1, grid_size
    do y = 1, grid_size
      d_center = sqrt((dble(x) - center) ** 2 + (dble(y) - center) ** 2)
      d_river = abs(dble(y) - (0.45d0 * dble(x) + 4.0d0))

      population = max(0.0d0, 120.0d0 + 500.0d0 * exp(-d_center / 7.0d0) + sin(dble(x * y)) * 25.0d0)
      hazard = min(1.0d0, exp(-d_river / 3.0d0) + 0.06d0)
      vulnerability = min(1.0d0, max(0.0d0, 0.25d0 + 0.45d0 * exp(-d_center / 9.0d0) + 0.03d0 * sin(dble(x + y))))
      risk_score = hazard * population * vulnerability

      accessibility = service_access(dble(x), dble(y))
      service_gap_score = population / (accessibility + 1.0d0)

      print '(I0,A,I0,A,F12.6,A,F12.6,A,F12.6,A,F12.6,A,F12.6,A,F12.6)', &
        x, ',', y, ',', population, ',', hazard, ',', vulnerability, ',', risk_score, ',', accessibility, ',', service_gap_score
    end do
  end do

contains

  real(8) function service_access(xcoord, ycoord)
    implicit none
    real(8), intent(in) :: xcoord, ycoord
    real(8) :: d1, d2, d3, d4

    d1 = sqrt((xcoord - 5.0d0) ** 2 + (ycoord - 6.0d0) ** 2)
    d2 = sqrt((xcoord - 9.0d0) ** 2 + (ycoord - 20.0d0) ** 2)
    d3 = sqrt((xcoord - 18.0d0) ** 2 + (ycoord - 10.0d0) ** 2)
    d4 = sqrt((xcoord - 22.0d0) ** 2 + (ycoord - 21.0d0) ** 2)

    service_access = 900.0d0 / (1.0d0 + d1 ** 2) + &
                     650.0d0 / (1.0d0 + d2 ** 2) + &
                     800.0d0 / (1.0d0 + d3 ** 2) + &
                     500.0d0 / (1.0d0 + d4 ** 2)
  end function service_access

end program geospatial_grid_solver
