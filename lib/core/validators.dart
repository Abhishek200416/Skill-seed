class Validators {
  static String? notEmpty(String? v, {String label='Field'}){ if(v==null||v.trim().isEmpty) return '$label is required'; return null; }
  static String? email(String? v){ final b=notEmpty(v,label:'Email'); if(b!=null) return b; final ok=RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v!.trim()); return ok?null:'Enter a valid email'; }
  static String? minLen(String? v, int len, {String label='Field'}){ final b=notEmpty(v,label:label); if(b!=null) return b; return v!.trim().length>=len?null:'$label must be at least $len chars'; }
}
