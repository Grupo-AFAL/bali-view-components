# frozen_string_literal: true

class TabsController < ApplicationController
  def tab1
    render plain: 'Tab 1 Content'
  end

  def tab2
    render plain: 'Tab 2 Content'
  end

  def tab3
    render plain: 'Tab 3 Content'
  end
end
