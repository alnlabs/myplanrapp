import '../../../shared/constants/asset_constants.dart';
import '../../../shared/utils/validators.dart';

String? validateServiceRecordShopName(String? value, {required String serviceType}) {
  if (serviceType == ServiceTypes.shopRepair) {
    return Validators.required(value);
  }
  return null;
}

String? validateServiceRecordCost(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  return Validators.positiveAmount(value);
}
