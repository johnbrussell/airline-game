module Islandable
  extend ActiveSupport::Concern

  include Demandable

  private

    def island_multipler
      island_to_island? ? 1 : 1/2.0
    end

    def island_to_island?
      if !defined?(@island_to_island)
        @island_to_island = origin_market.is_island && destination_market.is_island && !island_exception_exists?
      end
      @island_to_island
    end
end
