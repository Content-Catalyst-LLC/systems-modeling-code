program cascade_threshold
  implicit none
  character(len=16), dimension(4) :: sectors
  real, dimension(4) :: capacity, load, threshold
  real :: load_ratio
  integer :: i

  sectors = (/ 'energy          ', 'water           ', 'telecom         ', 'health          ' /)
  capacity = (/ 100.0, 85.0, 90.0, 95.0 /)
  load = (/ 62.0, 70.0, 58.0, 82.0 /)
  threshold = (/ 0.75, 0.70, 0.72, 0.78 /)

  print *, 'Cascade capacity diagnostics'

  do i = 1, 4
    load_ratio = load(i) / capacity(i)
    if (load_ratio >= threshold(i)) then
      print *, trim(sectors(i)), ' load_ratio=', load_ratio, ' threshold=', threshold(i), ' status=failure risk'
    else
      print *, trim(sectors(i)), ' load_ratio=', load_ratio, ' threshold=', threshold(i), ' status=within threshold'
    end if
  end do
end program cascade_threshold
