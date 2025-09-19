class Constants {
  static String _API_KEY = 'AIzaSyB7alyJjGKtzTgmMFlf_iuidTLPZS13GgU';
  static String _RAZORPAY_KEY = 'rzp_test_QXKKLlzZ8sGdkE';

  static const String _PLACEHOLDER_IMAGE =
      'https://placehold.co/600x400.png?text=!';

  static String get API_KEY => _API_KEY;
  static String get RAZORPAY_KEY => _RAZORPAY_KEY;
  static String get PLACEHOLDER_IMAGE => _PLACEHOLDER_IMAGE;

  void setApiKey(String newKey) {
    _API_KEY = newKey;
  }

  void setRazorPayKey(String newKey) {
    _RAZORPAY_KEY = newKey;
  }
}
