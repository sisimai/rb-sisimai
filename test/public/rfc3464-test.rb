require 'minitest/autorun'
require 'sisimai/rfc3464'

class RFC3464Test < Minitest::Test
  def headers
    {'content-type' => 'multipart/report; boundary=dsn; report-type=delivery-status'}
  end

  def original_message
    "Content-Type: message/rfc822\n\nFrom: sender@example.com\nTo: recipient@example.net\n\n"
  end

  def delivery_status
    "Content-Type: message/delivery-status\n\n" \
      "Reporting-MTA: dns; mx.example.com\n\n" \
      "Final-Recipient: rfc822; recipient@example.net\n" \
      "Action: failed\nStatus: 5.1.1\nDiagnostic-Code: smtp; 550 5.1.1 User unknown\n\n"
  end

  def test_empty_body
    assert_nil Sisimai::RFC3464.inquire(headers, '')
  end

  def test_original_message_without_a_body
    assert_nil Sisimai::RFC3464.inquire(headers, original_message)
  end

  def test_truncated_original_message
    assert_nil Sisimai::RFC3464.inquire(headers, "Content-Type: message/rfc822\n")
    assert_nil Sisimai::RFC3464.inquire(headers, "Content-Type: message/rfc822\n\nFrom: sender@example.com\n")
  end

  def test_delivery_status_with_an_empty_original_message_body
    result = Sisimai::RFC3464.inquire(headers, delivery_status + original_message)
    assert_equal 'recipient@example.net', result['ds'][0]['recipient']
    assert_equal '5.1.1', result['ds'][0]['status']
  end

  def test_delivery_status_inside_an_attached_message
    result = Sisimai::RFC3464.inquire(headers, original_message + delivery_status + original_message)
    assert_equal 'recipient@example.net', result['ds'][0]['recipient']
    assert_equal '5.1.1', result['ds'][0]['status']
  end
end
