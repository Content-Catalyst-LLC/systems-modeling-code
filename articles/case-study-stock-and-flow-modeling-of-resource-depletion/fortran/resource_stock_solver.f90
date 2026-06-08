program resource_stock_solver
  implicit none

  integer, parameter :: n = 6
  integer :: i, t
  character(len=24) :: names(n)
  real(8) :: initial_stock(n), regen(n), demand_growth(n), extraction_efficiency(n)
  real(8) :: conservation_sensitivity(n), max_conservation(n)
  real(8) :: stock, min_stock, demand, scarcity, conservation
  real(8) :: effective_demand, regeneration, extraction, cumulative_extraction, cumulative_regeneration
  integer :: overshoot_periods

  names = (/ &
    'baseline                ', &
    'high_demand             ', &
    'conservation            ', &
    'technology_rebound      ', &
    'regeneration_stress     ', &
    'delayed_governance      ' /)

  initial_stock = (/ 80.0d0, 80.0d0, 80.0d0, 80.0d0, 80.0d0, 80.0d0 /)
  regen = (/ 0.080d0, 0.080d0, 0.080d0, 0.080d0, 0.045d0, 0.080d0 /)
  demand_growth = (/ 0.015d0, 0.035d0, 0.015d0, 0.030d0, 0.015d0, 0.025d0 /)
  extraction_efficiency = (/ 0.120d0, 0.120d0, 0.120d0, 0.180d0, 0.120d0, 0.120d0 /)
  conservation_sensitivity = (/ 0.45d0, 0.45d0, 0.85d0, 0.35d0, 0.45d0, 0.20d0 /)
  max_conservation = (/ 0.35d0, 0.35d0, 0.55d0, 0.30d0, 0.35d0, 0.20d0 /)

  print '(A)', 'scenario,final_stock,minimum_stock,cumulative_extraction,cumulative_regeneration,overshoot_periods'

  do i = 1, n
    stock = initial_stock(i)
    min_stock = stock
    cumulative_extraction = 0.0d0
    cumulative_regeneration = 0.0d0
    overshoot_periods = 0

    do t = 0, 79
      demand = 4.0d0 * (1.0d0 + demand_growth(i)) ** t
      scarcity = max(0.0d0, 1.0d0 - stock / 70.0d0)
      conservation = min(max_conservation(i), conservation_sensitivity(i) * scarcity)
      effective_demand = demand * (1.0d0 - conservation)
      regeneration = regen(i) * stock * (1.0d0 - stock / 100.0d0)
      regeneration = max(0.0d0, regeneration)
      extraction = min(effective_demand, min(extraction_efficiency(i) * stock, stock + regeneration))

      if (extraction > regeneration) overshoot_periods = overshoot_periods + 1

      cumulative_extraction = cumulative_extraction + extraction
      cumulative_regeneration = cumulative_regeneration + regeneration
      stock = max(0.0d0, stock + regeneration - extraction)
      min_stock = min(min_stock, stock)
    end do

    print '(A,",",F10.6,",",F10.6,",",F10.6,",",F10.6,",",I3)', &
      trim(names(i)), stock, min_stock, cumulative_extraction, cumulative_regeneration, overshoot_periods
  end do

end program resource_stock_solver
