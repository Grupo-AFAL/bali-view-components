# frozen_string_literal: true

module DemoWidgets
  # A single figure, and the reason `ValueBase` defaults to `supports :small`:
  # there are no rows to show and nothing to chart, so a bigger canvas would be
  # this number in an empty box.
  class OverdueTasks < Bali::Widget::ValueBase
    default_size :small

    value { Task.where.not(status: :done).where(due_date: ...Date.current).count }
  end
end
