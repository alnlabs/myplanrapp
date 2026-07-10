Uri buildWhatsAppShareUri(String text) {
  return Uri.parse('https://wa.me/?text=${Uri.encodeComponent(text)}');
}
