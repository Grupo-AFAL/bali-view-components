# frozen_string_literal: true

module Bali
  module Concerns
    module Controllers
      # THE INBOX PAGE, THE POPOVER AND EVERY ACTION BEHIND THEM, FROM ONE CONTROLLER (#1512).
      #
      #   class InboxesController < ApplicationController
      #     include Bali::Concerns::Controllers::Inbox
      #   end
      #
      #   # config/routes.rb
      #   resource :inbox, only: :show do
      #     get :popover
      #     get :badge
      #     get "items/:kind/:gid", action: :item, as: :item
      #     get "items/:kind/:gid/open", action: :open_item, as: :open_item
      #     get "notices/:id/open", action: :open_notice, as: :open_notice
      #     post :read_all
      #   end
      #
      # It is the host's controller, so the host's authentication, layout and rescue apply —
      # which is why this is a concern and not an engine controller. Nothing here needs an
      # authorize lambda: every provider filters by the person, and every notice query by
      # recipient.
      #
      # Views: Bali's sit behind the controller's own (`_prefixes`), so
      # `app/views/inboxes/show.html.erb` in the host wins. A host partial
      # `inbox/items/_<kind>` replaces the generic detail for that kind; it gets `item`.
      #
      # `item`, `open_item` and `open_notice` are GETs that mark notices read, because viewing
      # is reading. Every link to them carries `data-turbo-prefetch="false"`: Turbo prefetches
      # a link on hover, and these would mark it read on hover.
      module Inbox
        extend ActiveSupport::Concern

        PER_PAGE = 20
        POPOVER_LIMIT = 10

        included do
          include InboxBadge

          helper Bali::InboxHelper
          helper_method :inbox_query, :inbox_tab

          before_action :require_inbox_owner
        end

        class_methods do
          # Rails already memoises `_prefixes`, so this must not memoise again.
          def _prefixes = super + %w[bali/inbox]
        end

        def show
          inbox_tab == "notices" ? load_notices : load_pending
        end

        def item
          @item = inbox_query.find(params[:kind], params[:gid])
          @gone = @item.nil?
          inbox_query.mark_seen!(@item) if @item
          return render(:item, layout: false) if request.headers["Turbo-Frame"].present?

          load_pending
          render :show
        end

        def popover
          return render(partial: "popover_notices", locals: popover_notices) if inbox_tab == "notices"

          @items = inbox_query.items.first(POPOVER_LIMIT)
          @fresh = inbox_query.fresh_keys(@items)
          @badge = Bali::Inbox::Badge.new(pending: inbox_query.count, unread: unread_notices.count)
          Bali::Inbox::Badge.write(inbox_owner, @badge)
          render :popover, layout: false
        end

        def badge
          render :badge, layout: false
        end

        def open_item
          item = inbox_query.find(params[:kind], params[:gid])
          if item.nil? || item.href.blank?
            return redirect_to(url_for(action: :item, kind: params[:kind], gid: params[:gid]), status: :see_other)
          end

          inbox_query.mark_seen!(item)
          redirect_to item.href, status: :see_other
        end

        def open_notice
          notice = Bali::Notice.addressed_to(inbox_owner).find(params[:id])
          notice.mark_read!
          redirect_to local_path(notice.action_url) || url_for(action: :show, tab: "notices"), status: :see_other
        end

        def read_all
          Bali::Notice.mark_all_read!(inbox_owner)
          respond_to do |format|
            format.turbo_stream { render :read_all, locals: popover_notices }
            format.html { redirect_to url_for(action: :show, tab: "notices"), status: :see_other }
          end
        end

        private

        def inbox_query = @inbox_query ||= Bali::Inbox::Query.new(inbox_owner)

        def inbox_tab = params[:tab] == "notices" ? "notices" : "pending"

        def require_inbox_owner
          head :unauthorized unless inbox_owner
        end

        def unread_notices = Bali::Notice.unread.listed.addressed_to(inbox_owner)

        def load_pending
          @kind = params[:kind].presence&.to_sym if action_name == "show"
          @module_key = params[:module].presence&.to_sym
          all = inbox_query.items(module_key: @module_key, kind: @kind)
          @page = page_param
          @items = all.slice((@page - 1) * PER_PAGE, PER_PAGE) || []
          @total = all.size
          @next_page = @page + 1 if @total > @page * PER_PAGE
          @fresh = inbox_query.fresh_keys(@items)
        end

        def load_notices
          scope = Bali::Notice.listed.addressed_to(inbox_owner)
          @page = page_param
          @notice_total = scope.count
          @notices = scope.recent.includes(:actor).offset((@page - 1) * PER_PAGE).limit(PER_PAGE).to_a
          @unread_count = unread_notices.count
        end

        def popover_notices
          { notices: Bali::Notice.listed.addressed_to(inbox_owner).recent.limit(POPOVER_LIMIT).to_a,
            unread_count: unread_notices.count }
        end

        def page_param = [ params[:page].to_i, 1 ].max

        # Only a path on this site: a notice's `action_url` is data, and `//host` or `/\host`
        # read as another site to a browser.
        def local_path(url)
          url if url.is_a?(String) && url.start_with?("/") && !url.start_with?("//") && !url.include?("\\")
        end
      end
    end
  end
end
