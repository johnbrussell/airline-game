class AirlineRouteRevenue::Allocator
  def self.allocate(solicitations, class_revenue)
    earned_revenue, unallocated_solicitations = allocate_detailed(solicitations, class_revenue)
    earned_revenue
  end

  def self.subtract_exclusive_allocations(solicitations, exclusive_revenue)
    earned_revenue, unallocated_solicitations = allocate_detailed(solicitations, exclusive_revenue)
    unallocated_solicitations
  end

  private

    def self.allocate_detailed(solicitations, class_revenue)
      unallocated_solicitations = solicitations.clone
      unallocated_revenue = class_revenue
      earned_revenue = solicitations.map { |airline_route, flights| [airline_route, 0] }.to_h

      while unallocated_solicitations.any? && unallocated_revenue.round(2) > 0
        new_unallocated_solicitations = {}
        new_unallocated_revenue = unallocated_revenue
        total_reputation = unallocated_solicitations.sum { |airline_route, flights| airline_route.reputation * flights.count }.to_f

        unallocated_solicitations.each do |airline_route, flights|
          desired_revenue_allocation_per_flight = airline_route.reputation.to_f / total_reputation * unallocated_revenue
          new_flights = flights.map do |flight|
            actual_revenue_allocation = [desired_revenue_allocation_per_flight, flight].min
            earned_revenue[airline_route] += actual_revenue_allocation
            new_unallocated_revenue -= actual_revenue_allocation
            flight - actual_revenue_allocation unless flight <= desired_revenue_allocation_per_flight || flight == 0
          end.compact
          new_unallocated_solicitations[airline_route] = new_flights if new_flights.any?
        end

        unallocated_solicitations = new_unallocated_solicitations
        unallocated_revenue = new_unallocated_revenue
      end

      [earned_revenue, unallocated_solicitations]
    end
end
