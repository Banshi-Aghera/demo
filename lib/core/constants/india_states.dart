/// States and union territories with their GST state codes. The code decides
/// CGST+SGST (same state as seller) vs IGST (other state) on invoices.
class IndiaState {
  const IndiaState(this.name, this.gstCode);
  final String name;
  final String gstCode;
}

const indiaStates = <IndiaState>[
  IndiaState('Andaman and Nicobar Islands', '35'),
  IndiaState('Andhra Pradesh', '37'),
  IndiaState('Arunachal Pradesh', '12'),
  IndiaState('Assam', '18'),
  IndiaState('Bihar', '10'),
  IndiaState('Chandigarh', '04'),
  IndiaState('Chhattisgarh', '22'),
  IndiaState('Dadra and Nagar Haveli and Daman and Diu', '26'),
  IndiaState('Delhi', '07'),
  IndiaState('Goa', '30'),
  IndiaState('Gujarat', '24'),
  IndiaState('Haryana', '06'),
  IndiaState('Himachal Pradesh', '02'),
  IndiaState('Jammu and Kashmir', '01'),
  IndiaState('Jharkhand', '20'),
  IndiaState('Karnataka', '29'),
  IndiaState('Kerala', '32'),
  IndiaState('Ladakh', '38'),
  IndiaState('Lakshadweep', '31'),
  IndiaState('Madhya Pradesh', '23'),
  IndiaState('Maharashtra', '27'),
  IndiaState('Manipur', '14'),
  IndiaState('Meghalaya', '17'),
  IndiaState('Mizoram', '15'),
  IndiaState('Nagaland', '13'),
  IndiaState('Odisha', '21'),
  IndiaState('Puducherry', '34'),
  IndiaState('Punjab', '03'),
  IndiaState('Rajasthan', '08'),
  IndiaState('Sikkim', '11'),
  IndiaState('Tamil Nadu', '33'),
  IndiaState('Telangana', '36'),
  IndiaState('Tripura', '16'),
  IndiaState('Uttar Pradesh', '09'),
  IndiaState('Uttarakhand', '05'),
  IndiaState('West Bengal', '19'),
];

IndiaState? stateByName(String name) {
  for (final s in indiaStates) {
    if (s.name == name) return s;
  }
  return null;
}
