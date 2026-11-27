/// Centralised Persian strings for navigation, shared actions and empty states.
///
/// Screen-specific copy stays close to its widget, but recurring labels live
/// here so the product voice stays consistent.
abstract final class FaStrings {
  static const appName = 'دارام';
  static const tagline = 'پولت رو بشناس، هوشمندانه زندگی کن.';

  // Navigation
  static const navChat = 'دستیار';
  static const navDashboard = 'آمار';
  static const navRecords = 'اطلاعات مالی';
  static const navSettings = 'تنظیمات';

  // Common actions
  static const save = 'ذخیره';
  static const cancel = 'انصراف';
  static const confirm = 'تأیید و ثبت';
  static const confirmAll = 'تأیید همه';
  static const reject = 'رد کردن';
  static const edit = 'ویرایش';
  static const delete = 'حذف';
  static const undo = 'برگرداندن';
  static const retry = 'تلاش دوباره';
  static const close = 'بستن';
  static const done = 'تمام';
  static const add = 'افزودن';
  static const search = 'جست‌وجو';
  static const today = 'امروز';
  static const yesterday = 'دیروز';
  static const thisMonth = 'این ماه';
  static const lastMonth = 'ماه گذشته';
  static const customRange = 'بازه دلخواه';

  // Chat
  static const chatTitle = 'دستیار مالی';
  static const chatEmptyTitle = 'سلام، من دارام هستم';
  static const chatEmptyMessage =
      'کافیه مثل یک گفتگو بنویسی چه هزینه یا درآمدی داشتی؛ من پیش‌نویس می‌سازم و قبل از ثبت از تو تأیید می‌گیرم.';
  static const chatHint = 'مثلاً: امروز ۲۵۰ هزار تومان ناهار خوردم…';
  static const newChat = 'گفتگوی جدید';
  static const conversations = 'گفتگوها';
  static const searchConversations = 'جست‌وجوی گفتگو';
  static const noConversations = 'هنوز گفتگویی نداری';
  static const aiNotConfigured = 'دستیار هوشمند هنوز تنظیم نشده است';
  static const configureAI = 'تنظیم دستیار';
  static const thinking = 'دارام در حال فکر کردن است…';
  static const stop = 'توقف';
  static const send = 'ارسال';
  static const draftPending = 'در انتظار تأیید تو';
  static const confirmed = 'ثبت شد';
  static const rejected = 'رد شد';
  static const undoSuccess = 'عملیات برگشت داده شد.';

  // Quick actions
  static const quickExpense = 'ثبت هزینه';
  static const quickIncome = 'ثبت درآمد';
  static const quickAddAccount = 'افزودن حساب';
  static const quickTodayReport = 'گزارش امروز';
  static const quickMonthReport = 'گزارش این ماه';
  static const quickLoans = 'وضعیت وام‌ها';
  static const quickOverview = 'وضعیت مالی من';
  static const quickRoadmap = 'نقشه راه مالی';

  // Records
  static const accounts = 'حساب‌ها';
  static const transactions = 'تراکنش‌ها';
  static const loans = 'وام‌ها';
  static const transfers = 'انتقال‌ها';
  static const noAccounts = 'هنوز حسابی ثبت نشده';
  static const noTransactions = 'هنوز تراکنشی ثبت نشده';
  static const noLoans = 'هنوز وامی ثبت نشده';
  static const addAccount = 'افزودن حساب';
  static const addTransaction = 'ثبت تراکنش';
  static const addLoan = 'افزودن وام';

  // Settings
  static const appearance = 'ظاهر';
  static const currency = 'واحد پول';
  static const numberFormat = 'نمایش اعداد';
  static const aiSection = 'دستیار هوشمند';
  static const dataManagement = 'مدیریت داده‌ها';
  static const categories = 'دسته‌بندی‌ها';
  static const about = 'درباره دارام';
  static const privacy = 'حریم خصوصی';
}
