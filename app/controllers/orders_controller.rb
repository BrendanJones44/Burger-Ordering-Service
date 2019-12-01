class OrdersController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:receive_completed, :receive_grilled, :receive_condiments_applied, :receive_wrapped]
  def show
    @order = Order.new
    @initial_order_id = SecureRandom.hex(10)
  end

  def create
    response_hash = {
      action: 'order_placed',
      order: order_params,
      next_id: SecureRandom.hex(10)
    }

    sns = Aws::SNS::Resource.new(
      region: 'us-east-2',
      access_key_id: ENV['AWS_ACCESS_KEY_ID'],
      secret_access_key: ENV['AWS_SECRET_ACCESS_KEY']
    )

    topic = sns.topic(ENV['AWS_SNS_ARN'])

    topic.publish({
      message: order_params.to_s
    })

    # Tell the channel an order has been placed
    ActionCable.server.broadcast 'order_screen_channel', content: response_hash

    # Return successful created
    :created
  end

  def receive_completed
    response_hash = {
      action: 'order_completed',
      order: order_updated_params
    }
    ActionCable.server.broadcast 'order_screen_channel', content: response_hash
  end

  def receive_grilled
    response_hash = {
      action: 'order_grilled',
      order: order_updated_params
    }
    ActionCable.server.broadcast 'order_screen_channel', content: response_hash
  end

  def receive_condiments_applied
    response_hash = {
      action: 'order_condiments_applied',
      order: order_updated_params
    }
    ActionCable.server.broadcast 'order_screen_channel', content: response_hash
  end

  def receive_wrapped
    response_hash = {
      action: 'order_wrapped',
      order: order_updated_params
    }
    ActionCable.server.broadcast 'order_screen_channel', content: response_hash
  end

  private

  def order_params
    params.require(:order).permit(:id, :name)
  end

  def order_updated_params
    params.require(:order).permit(:id)
  end
end
