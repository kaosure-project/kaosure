// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get languageSystem => '跟随系统';

  @override
  String get languageSaveFailed => '无法保存语言，请重试。';

  @override
  String get appName => 'KaoSure';

  @override
  String get kaoId => 'Kao ID';

  @override
  String get settings => '设置';

  @override
  String get language => '语言';

  @override
  String get languageThai => '泰语';

  @override
  String get languageEnglish => '英语';

  @override
  String get languageChineseSimplified => '简体中文';

  @override
  String get languageJapanese => '日语';

  @override
  String get languageBurmese => '缅甸语';

  @override
  String get security => '安全';

  @override
  String get password => '密码';

  @override
  String get changePassword => '修改密码';

  @override
  String get cancel => '取消';

  @override
  String get save => '保存';

  @override
  String get continueLabel => '继续';

  @override
  String get back => '返回';

  @override
  String get notifications => '通知';

  @override
  String get notificationPreferencesDescription => '管理通知偏好';

  @override
  String get privacy => '隐私';

  @override
  String get privacyPermissionsDescription => '隐私与权限';

  @override
  String get aboutKaoId => '关于 Kao ID';

  @override
  String get aboutKaoIdDescription => '版本、许可证及法律信息';

  @override
  String get passwordChangeDescription => '修改您的密码';

  @override
  String get devices => '设备';

  @override
  String get trustedDevicesDescription => '管理可信设备';

  @override
  String get loginHistory => '登录历史';

  @override
  String get loginHistoryDescription => '近期登录活动';

  @override
  String get twoFactorAuthentication => '双因素认证';

  @override
  String get twoFactorDescription => '保护您的账户';

  @override
  String get services => '服务';

  @override
  String get marketplace => '交易市场';

  @override
  String get marketplaceDescription => '在 KaoSure 买卖商品';

  @override
  String get auction => '拍卖';

  @override
  String get auctionDescription => '商品拍卖';

  @override
  String get kaoPay => 'KaoPay';

  @override
  String get kaoPayDescription => '数字钱包';

  @override
  String get moreServices => '更多服务';

  @override
  String get moreServicesDescription => '探索 Kao Ecosystem 服务';

  @override
  String get serviceUnavailable => '暂未开放';

  @override
  String get quickActions => '快捷操作';

  @override
  String get profile => '个人资料';

  @override
  String get verifyIdentity => '验证身份';

  @override
  String get kaoCode => 'Kao Code';

  @override
  String get accountTitle => '我的账户';

  @override
  String get accountSecurity => '账户与安全';

  @override
  String get identityVerification => '身份验证';

  @override
  String get identityVerificationDescription => '验证身份以提高账户安全性';

  @override
  String get bankAccounts => '银行账户';

  @override
  String get bankAccountsDescription => '管理收款银行账户';

  @override
  String get accountDevicesDescription => '查看和管理已登录设备';

  @override
  String get accountSessions => '会话与登录';

  @override
  String get accountSessionsDescription => '查看登录活动';

  @override
  String get businessAccount => '企业账户';

  @override
  String get organizations => '公司／组织';

  @override
  String get organizationsDescription => '管理组织和访问权限';

  @override
  String get accountLanguageDescription => '管理 Kao ID 语言';

  @override
  String get accountNotificationsDescription => '管理 Kao ID 通知';

  @override
  String get retry => '重试';

  @override
  String get profileNotFound => '未找到个人资料';

  @override
  String get profileSaved => '个人资料已保存';

  @override
  String get editProfile => '编辑个人资料';

  @override
  String get kaoIdAvailableAfterVerification => '身份验证后可用';

  @override
  String get displayName => '显示名称';

  @override
  String get displayNameExample => '例如：KaoSure Official';

  @override
  String get profileSharedDescription => '您的显示名称和照片用于各项 Kao ID 服务，之后可以修改。';

  @override
  String get displayNameMinLength => '名称至少需要 3 个字符';

  @override
  String get displayNameMaxLength => '名称不得超过 30 个字符';

  @override
  String get profileVisibilityDescription => '您的头像和名称会显示在各项 Kao ID 服务中';

  @override
  String get editYourProfile => '编辑您的个人资料';

  @override
  String get profileDescription =>
      '您可以修改 Kao ID 的显示名称和头像。这些信息会显示在交易市场及其他 Kao Ecosystem 服务中。';

  @override
  String get profileDetails => '详情';

  @override
  String get accountVerified => '身份已验证';

  @override
  String get organizationAccount => '组织账户';

  @override
  String get accountRegistered => '已注册';

  @override
  String get accountStandard => '标准账户';

  @override
  String get completeProfile => '完善资料';

  @override
  String get completeYourProfile => '完善您的个人资料';

  @override
  String get completeProfileDescription => '设置您的 Kao ID 基本资料。';

  @override
  String get displayNameHint => '其他用户看到的名称';

  @override
  String get displayNameRequired => '请输入显示名称';

  @override
  String get displayNameTooLong => '显示名称不得超过 100 个字符';

  @override
  String get preferredLanguage => '首选语言';

  @override
  String get languageCodeHint => '例如：th 或 en';

  @override
  String get languageRequired => '请输入语言';

  @override
  String get saveProfile => '保存个人资料';

  @override
  String get profileLoadFailed => '无法加载个人资料，请重试。';

  @override
  String get profileSaveFailed => '无法保存个人资料，请重试。';

  @override
  String get kaoIdUser => 'Kao ID 用户';

  @override
  String get usernameNotSet => '尚未设置用户名';

  @override
  String accountCompletion(int percent) {
    return '账户完成度 $percent%';
  }

  @override
  String get dashboardLoadFailed => '无法加载账户，请重试。';

  @override
  String get homeLabel => '首页';

  @override
  String get homeIntroduction => '集中管理您的账户和安全设置。';

  @override
  String get viewProfile => '查看个人资料';

  @override
  String get identityEntryDescription => '通过 Kao ID 查看状态并继续身份验证。';

  @override
  String get viewIdentityStatus => '查看验证状态';

  @override
  String get governanceLabel => '管理后台';

  @override
  String get governanceDescription => '根据分配的权限管理平台';

  @override
  String get authLogin => '登录';

  @override
  String get authRegister => '注册';

  @override
  String get authCreateAccount => '创建账户';

  @override
  String get authEmail => '电子邮箱';

  @override
  String get authEmailHint => '请输入电子邮箱';

  @override
  String get authEmailRequired => '请输入电子邮箱';

  @override
  String get authEmailInvalid => '请输入有效的电子邮箱地址';

  @override
  String get authPasswordHint => '请输入密码';

  @override
  String get authPasswordRequired => '请输入密码';

  @override
  String get authPasswordMinLength => '至少使用 8 个字符';

  @override
  String get authPasswordNumberRequired => '至少包含一个数字';

  @override
  String get authPasswordSpecialRequired => '至少包含一个特殊字符';

  @override
  String get authConfirmPassword => '确认密码';

  @override
  String get authConfirmPasswordHint => '请再次输入密码';

  @override
  String get authConfirmPasswordRequired => '请确认密码';

  @override
  String get authPasswordMismatch => '两次密码不一致';

  @override
  String get authForgotPassword => '忘记密码';

  @override
  String get authForgotPasswordLink => '忘记密码？';

  @override
  String get authExistingAccount => '已有账户？登录';

  @override
  String get authRegistrationSucceeded => '账户已创建';

  @override
  String get authSendResetLink => '发送重置链接';

  @override
  String get authResetLinkSent => '如果此邮箱可用于恢复账户，您将收到重置链接。';

  @override
  String get authVerifyEmail => '验证邮箱';

  @override
  String get authVerificationEmailSent => '验证邮件已发送';

  @override
  String get authEmailNotVerified => '邮箱尚未验证';

  @override
  String get authEmailVerified => '邮箱已验证';

  @override
  String get authVerifyEmailInstructions => '打开验证邮件并点击链接。如果找不到邮件，可以请求重新发送。';

  @override
  String get authResendVerificationEmail => '重新发送验证邮件';

  @override
  String get authCheckAgain => '再次检查';

  @override
  String get authVerifyLater => '稍后验证';

  @override
  String get authNewPassword => '新密码';

  @override
  String get authNewPasswordHint => '请输入新密码';

  @override
  String get authNewPasswordRequired => '请输入新密码';

  @override
  String get authConfirmNewPassword => '确认新密码';

  @override
  String get authConfirmNewPasswordHint => '请再次输入新密码';

  @override
  String get authConfirmNewPasswordRequired => '请确认新密码';

  @override
  String get authResetPassword => '重置密码';

  @override
  String get authPasswordChanged => '密码已修改';

  @override
  String get authInvalidRecoveryLink => '此密码重置链接无效或已过期';

  @override
  String get authInvalidRecoveryDescription => '请请求新的重置链接以确认密码修改。';

  @override
  String get authRequestNewLink => '请求新链接';

  @override
  String get authVerificationCodeSent => '验证码已发送';

  @override
  String get authSendCodeFailed => '无法发送验证码，请重试。';

  @override
  String get authChangePasswordFailed => '无法修改密码，请检查验证码后重试。';

  @override
  String get authVerificationCodeRequired => '请输入验证码';

  @override
  String get authReauthenticateTitle => '修改密码前验证';

  @override
  String get authReauthenticateDescription => '为保障安全，我们将向账户中已验证的邮箱或电话号码发送验证码。';

  @override
  String get authSendCode => '发送验证码';

  @override
  String get authVerificationCode => '验证码';

  @override
  String get authVerificationCodeHint => '请输入收到的验证码';

  @override
  String get authSending => '正在发送…';

  @override
  String get authResendCode => '重新发送验证码';

  @override
  String get authRequirementsTitle => '密码要求：';

  @override
  String get authRequirementLength => '至少 8 个字符';

  @override
  String get authRequirementNumber => '一个数字';

  @override
  String get authRequirementSpecial => '一个特殊字符';

  @override
  String get authWelcome => '欢迎使用 Kao ID';

  @override
  String get authLoginFailed => '无法登录，请检查信息后重试。';

  @override
  String get authRegistrationFailed => '无法创建账户，请检查信息后重试。';

  @override
  String get authResetRequestFailed => '无法请求重置链接，请重试。';

  @override
  String get authVerificationFailed => '无法检查邮箱验证状态或重新发送验证邮件，请重试。';

  @override
  String get authResetFailed => '无法重置密码，请重试或请求新链接。';

  @override
  String get authShowPassword => '显示密码';

  @override
  String get authHidePassword => '隐藏密码';

  @override
  String get authBootstrapFailed => '无法打开账户，请重试。';

  @override
  String get signOut => '退出登录';

  @override
  String get signOutConfirmation => '确定退出登录吗？';

  @override
  String get signOutFailed => '无法退出登录，请重试。';

  @override
  String get kycLoadFailed => '无法加载验证信息，请重试。';

  @override
  String get kycInformation => '验证信息';

  @override
  String get kycInformationDescription => '管理您的身份验证信息和证件。';

  @override
  String get kycPermissions => '访问权限';

  @override
  String get kycPermissionsDescription => '您的访问权限取决于验证状态。';

  @override
  String get accountHubIntroduction => '按类别管理您的账户。';

  @override
  String get personalDetailsTitle => '个人信息';

  @override
  String get personalDetailsDescription => '查看和编辑显示名称及头像。';

  @override
  String get securityHubDescription => '管理账户密码。';

  @override
  String get settingsHubDescription => '选择语言和退出登录。';

  @override
  String get openSectionLabel => '打开此项';

  @override
  String get kycHubIntro => '按类别管理联系信息验证和身份证件。';

  @override
  String get kycContactGroup => '联系信息验证';

  @override
  String get kycDocumentsGroup => '身份证件';

  @override
  String get kycOtherGroup => '补充信息';

  @override
  String get kycEmailTitle => '电子邮箱';

  @override
  String get kycPhoneTitle => '电话号码';

  @override
  String get kycIdCardTitle => '国民身份证';

  @override
  String get kycPassportTitle => '护照';

  @override
  String get kycResidenceTitle => '居留许可';

  @override
  String get kycBankTitle => '银行账户';

  @override
  String get kycHistoryTitle => '验证历史';

  @override
  String get kycUnknownStatus => '无法获取状态';

  @override
  String get kycVerifiedStatus => '已验证';

  @override
  String get kycUnverifiedStatus => '未验证';

  @override
  String get kycPendingStatus => '审核中';

  @override
  String get kycRejectedStatus => '未获批准';

  @override
  String get kycExpiredStatus => '已过期';

  @override
  String get kycCancelledStatus => '已取消';

  @override
  String get kycNoRequest => '暂无验证申请';

  @override
  String get kycRequestTitle => '最新申请';

  @override
  String get kycHistoryDescription => '查看审核结果和状态变更。';

  @override
  String get kycHistoryEmpty => '暂无验证历史。';

  @override
  String get kycHistoryFailed => '无法加载验证历史，请重试。';

  @override
  String get kycHistoryEvent => '验证更新';

  @override
  String get kycActionApprove => '验证已批准';

  @override
  String get kycActionReject => '验证已拒绝';

  @override
  String get kycActionReview => '已开始审核';

  @override
  String get kycActionSubmit => '已提交验证';

  @override
  String get kycActionCancel => '申请已取消';

  @override
  String get kycResidenceLimited => '查看已有信息，暂不支持上传';

  @override
  String get kycRequestFailed => '无法提交申请，请重试。';

  @override
  String get contactPhoneInvalid => '请输入泰国手机号码，或以 + 开头的国际号码。';

  @override
  String get contactOtpInvalid => '请输入收到的 6–10 位验证码。';

  @override
  String get contactOtpFailed => '无法验证验证码，可能有误或已过期，请重试。';

  @override
  String get contactSendFailed => '无法发送验证码，请稍后重试。';

  @override
  String get contactStillPending => '新号码尚未确认，请再次检查。';

  @override
  String get contactSessionChanged => '登录账户已变更，请重新打开此页面。';

  @override
  String get contactLoadFailed => '无法加载您的信息，请再次检查。';

  @override
  String get contactPhoneIntro => '确认此号码能接收验证码。新号码仅在服务器验证后生效。';

  @override
  String get contactNoPhone => '未登记电话号码';

  @override
  String get contactPhoneFormat => '例如：0812345678 或 +66812345678';

  @override
  String get contactWait => '请稍候再发送';

  @override
  String get contactSendCode => '发送验证码';

  @override
  String get contactCodeDestination => '验证码已发送至';

  @override
  String get contactOtpLabel => '验证码';

  @override
  String get contactVerifyCode => '验证代码';

  @override
  String get contactExpiryHelp => '请使用最新收到的验证码。如果过期，请在按钮可用后重新请求。';

  @override
  String get contactEmailRefreshHelp => '打开邮件链接后，请返回此处再次检查。如果链接过期，请请求新邮件。';

  @override
  String get changeEmailTitle => '更改邮箱地址';

  @override
  String get changePhoneTitle => '更改电话号码';

  @override
  String get changeContactIntro => '确认密码以申请变更。在新联系方式确认前，原联系方式继续有效。';

  @override
  String get changeContactCurrent => '当前联系方式';

  @override
  String get changeContactPending => '等待确认';

  @override
  String get changeEmailPending => '请打开确认邮件。您可能需要确认当前和新的两个邮箱，然后选择“再次检查”。';

  @override
  String get changeEmailNew => '新邮箱地址';

  @override
  String get changePhoneNew => '新电话号码';

  @override
  String get changeContactPassword => '当前密码';

  @override
  String get changeContactPasswordHelp =>
      '请使用 Kao ID 密码。如果仅通过外部服务登录且没有密码，请先通过账户恢复设置密码。';

  @override
  String get changeContactRequest => '申请变更／重新发送确认';

  @override
  String get changeContactDone => '新联系方式已确认。';

  @override
  String get changeContactSame => '请输入不同的邮箱地址或电话号码。';

  @override
  String get changeEmailInvalid => '请输入有效的邮箱地址。';

  @override
  String get changeContactPasswordRequired => '请输入当前密码。';

  @override
  String get changeContactFailed =>
      '无法完成申请。请检查密码和验证码，等待规定时间后重试。再次申请变更前请先检查当前状态。';

  @override
  String get changeContactMfaRequired => '请输入已登记的身份验证器应用中的代码。';

  @override
  String get changeContactMfaDevice => '身份验证器';

  @override
  String get changeContactMfaCode => '身份验证器代码';

  @override
  String get kycNationalIdCard => '国民身份证';

  @override
  String get kycUseYourNationalIdCardFor => '使用国民身份证进行身份验证。';

  @override
  String get kycChooseFrontImage => '选择正面图片';

  @override
  String get kycChooseBackImage => '选择背面图片';

  @override
  String get kycFrontImageSelected => '已选择正面图片';

  @override
  String get kycBackImageSelected => '已选择背面图片';

  @override
  String get kycVerifyWithYourNationalIdCard => '使用国民身份证验证';

  @override
  String get kycUseYourOriginalIdCardMake => '请使用身份证原件，确保所有信息清晰可见且无反光。';

  @override
  String get kycDocumentRequirements => '证件要求';

  @override
  String get kycBothSidesMustBeClear => '正反两面均须清晰';

  @override
  String get kycIncludeAllInformationOnTheCard => '包含卡片上的所有信息';

  @override
  String get kycAvoidGlareAndBlurredImages => '避免反光和模糊';

  @override
  String get kycDocumentsAreUsedForIdentityVerification => '证件用于身份验证';

  @override
  String get kycSubmitIdentityDocumentsOnlyThroughKao => '请仅通过 Kao ID 提交身份证件。';

  @override
  String get kycPassport => '护照';

  @override
  String get kycAddYourPassportInformationForIdentity => '添加护照信息以验证身份';

  @override
  String get kycPassportNumber => '护照号码';

  @override
  String get kycEnterTheNumberPrintedOnYour => '请输入护照上印制的号码';

  @override
  String get kycForExampleAa => '例如：AA1234567';

  @override
  String get kycEnterYourPassportNumber => '请输入护照号码';

  @override
  String get kycInvalidPassportNumber => '护照号码无效';

  @override
  String get kycDocumentDates => '证件日期';

  @override
  String get kycPassportIssueAndExpiryDates => '护照签发日期和有效期';

  @override
  String get kycIssueDate => '签发日期';

  @override
  String get kycExpiryDate => '到期日期';

  @override
  String get kycPassportDocument => '护照证件';

  @override
  String get kycChooseAClearImageOfThe => '请选择清晰的护照个人信息页图片';

  @override
  String get kycAddPassportImage => '添加护照图片';

  @override
  String get kycTapToSelectAFileFrom => '点击从设备选择文件';

  @override
  String get kycFileSelectedNotSubmittedYet => '已选择文件，尚未提交';

  @override
  String get kycChangeFile => '更换文件';

  @override
  String get kycDocumentPrivacy => '证件隐私';

  @override
  String get kycDocumentsAreUsedForIdentityVerification32 =>
      '证件用于身份验证。选择文件并不代表提交。';

  @override
  String get kycSaving => '正在保存…';

  @override
  String get kycSavePassport => '保存护照';

  @override
  String get kycSelectBothIssueAndExpiryDates => '请选择签发日期和到期日期';

  @override
  String get kycExpiryDateMustBeAfterIssue => '到期日期必须晚于签发日期';

  @override
  String get kycSelectAPassportImage => '请选择护照图片';

  @override
  String get kycPleaseSignInAgain => '请重新登录';

  @override
  String get kycPassportSaved => '护照已保存';

  @override
  String get kycSelectDate => '选择日期';

  @override
  String get kycResidencePermit => '居留许可';

  @override
  String get kycAResidencePermitIsUsedTo => '居留许可用于验证您的居留资格。';

  @override
  String get kycStatus => '状态';

  @override
  String get kycNoResidencePermitAdded => '尚未添加居留许可';

  @override
  String get kycUploadResidencePermit => '上传居留许可';

  @override
  String get kycFrontOfCard => '卡片正面';

  @override
  String get kycBackOfCard => '卡片背面';

  @override
  String get kycToday => '今天';

  @override
  String get kycYouCanChooseAnotherFileTo => '可以选择其他文件替换当前选择';

  @override
  String get kycSelected => '已选择';

  @override
  String get kycUploadRequirements => '上传要求';

  @override
  String get kycCheckTheInformationBeforeSubmitting => '提交前请检查信息';

  @override
  String get kycChooseImagesOfBothSidesOf => '请选择国民身份证正反两面的图片';

  @override
  String get kycJpgAndPngSupported => '支持 JPG 和 PNG';

  @override
  String get kycCheckThatTheImageIsClear => '选择前请确认图片清晰';

  @override
  String get kycSelectingAFileDoesNotUpload => '选择文件不会上传或提交文件';

  @override
  String get kycFileName => '文件名';

  @override
  String get kycFileSize => '文件大小';

  @override
  String get kycUploadedOn => '上传日期';

  @override
  String get kycChooseDocument => '选择证件';

  @override
  String get kycTapToSelectAFileFrom61 => '点击从设备选择文件';

  @override
  String get kycChooseFile => '选择文件';

  @override
  String get kycProcessing => '正在处理…';

  @override
  String get kycCheckThatTheImageIsClear64 => '选择前请确认图片清晰';

  @override
  String get kycSelectingAFileDoesNotUpload65 => '选择文件不会上传或提交文件';

  @override
  String get kycApproved => '已批准';

  @override
  String get kycAwaitingReview => '等待审核';

  @override
  String get kycRejected => '已拒绝';

  @override
  String get kycNoDocumentSubmitted => '尚未提交证件';

  @override
  String get kycBankAccount => '银行账户';

  @override
  String get kycAddingBankAccountsIsNotAvailable => '暂不支持添加银行账户';

  @override
  String get kycManagingBankAccountsIsNotAvailable => '暂不支持管理银行账户';

  @override
  String get kycBankAccountVerification => '银行账户验证';

  @override
  String get kycViewBankAccountVerificationForKao =>
      '查看 Kao Ecosystem 服务的银行账户验证情况';

  @override
  String get kycCheckAccountStatusAndItsMatch => '检查账户状态及其与 KYC 信息是否一致';

  @override
  String get kycLoadingBankAccountDetails => '正在加载银行账户信息…';

  @override
  String get kycCouldNotLoadTheDetails => '无法加载信息';

  @override
  String get kycTryAgain => '重试';

  @override
  String get kycNoBankAccountAdded => '尚未添加银行账户';

  @override
  String get kycBankAccountRegistrationIsNotAvailable => '银行账户登记暂未开放。';

  @override
  String get kycAddBankAccount => '添加银行账户';

  @override
  String get kycAccountHolderName => '账户持有人姓名';

  @override
  String get kycPrimaryAccount => '主要账户';

  @override
  String get kycAccountNumber => '账户号码';

  @override
  String get kycVerificationStatus => '验证状态';

  @override
  String get kycNameMatchWithKyc => '姓名与 KYC 信息匹配情况';

  @override
  String get kycRejectionReason => '拒绝原因';

  @override
  String get kycVerifiedBankAccount => '已验证的银行账户';

  @override
  String get kycSecurity => '安全';

  @override
  String get kycTheAccountIsVerifiedAndIts => '账户已验证，持有人姓名与已验证身份一致';

  @override
  String get kycTheAccountHolderNameMustMatch => '账户持有人姓名须与已验证身份一致，才能认定为可信账户';

  @override
  String get kycCheckAgain => '再次检查';

  @override
  String get kycManageBankAccount => '管理银行账户';

  @override
  String get kycVerified => '已验证';

  @override
  String get kycTheBankAccountHasBeenVerified => '银行账户已验证';

  @override
  String get kycUnderReview => '审核中';

  @override
  String get kycTheBankAccountIsBeingReviewed => '银行账户正在审核中';

  @override
  String get kycAdditionalReview => '补充审核';

  @override
  String get kycFurtherReviewIsRequired => '需要进一步审核';

  @override
  String get kycNotVerified => '未验证';

  @override
  String get kycTheBankAccountDidNotPass => '银行账户未通过验证';

  @override
  String get kycExpired => '已过期';

  @override
  String get kycTheBankAccountVerificationHasExpired => '银行账户验证已过期';

  @override
  String get kycVerificationNotStarted => '尚未开始验证';

  @override
  String get kycTheBankAccountHasNotEntered => '银行账户尚未进入验证流程';

  @override
  String get kycAccountNameMatchesKyc => '账户姓名与 KYC 信息一致';

  @override
  String get kycTheAccountHolderNameMatchesThe => '账户持有人姓名与已验证身份一致';

  @override
  String get kycAccountNameDoesNotMatchKyc => '账户姓名与 KYC 信息不一致';

  @override
  String get kycTheAccountHolderNameDiffersFrom => '账户持有人姓名与已验证身份不同';

  @override
  String get kycReviewingAccountName => '正在审核账户姓名';

  @override
  String get kycMoreInformationMustBeReviewedBefore => '作出决定前需审核更多信息';

  @override
  String get kycAwaitingNameCheck => '等待姓名核查';

  @override
  String get kycTheAccountHolderNameWillBe => '将根据 KYC 信息核查账户持有人姓名';

  @override
  String get kycDocumentSaveFailed => '无法保存证件，请重试。';

  @override
  String get contactVerifiedHelp => '此联系方式已验证，可以在下方申请变更。';

  @override
  String get kycRejectedLabel => '已拒绝';

  @override
  String get kycNotAdded => '未添加';

  @override
  String get kycExpiryDateNotProvided => '未提供到期日期';

  @override
  String get kycSelectPassportExpiryDate => '选择护照到期日期';

  @override
  String get kycCancel => '取消';

  @override
  String get kycSelect => '选择';

  @override
  String get kycNoBankAccountAddedLabel => '尚未添加银行账户';

  @override
  String get kycAdditionalReviewLabel => '补充审核';

  @override
  String get kycNotVerifiedLabel => '未验证';

  @override
  String get kycNameMatchesKyc => '姓名与 KYC 信息一致';

  @override
  String get kycNameDoesNotMatch => '姓名不一致';

  @override
  String get kycAdditionalNameReview => '姓名补充审核';

  @override
  String get kycAwaitingKycNameCheck => '等待 KYC 姓名核查';

  @override
  String get kycVerifiedLabel => '已验证';

  @override
  String get kycVerificationHistory => '验证历史';

  @override
  String get kycReviewVerificationResultsAndChanges => '查看验证结果和变更';

  @override
  String get kycIdentityVerificationProgress => '身份验证进度';

  @override
  String get kycYourIdentityVerificationIsComplete => '您的身份验证已完成';

  @override
  String get kycVerifyAdditionalInformationToCompleteYourIdentity =>
      '验证补充信息以完成身份验证';

  @override
  String get kycVerificationComplete => '验证完成';

  @override
  String get kycInProgress => '进行中';

  @override
  String get kycChooseAnotherFile => '选择其他文件';

  @override
  String get kycEmail => '电子邮箱';

  @override
  String get kycNotVerifiedLabelText => '未验证';

  @override
  String get kycPhoneNumber => '电话号码';

  @override
  String get kycInformationRecorded => '信息已记录';

  @override
  String get kycAccessPermissions => '访问权限';

  @override
  String get kycIdentityVerified => '身份已验证';

  @override
  String get kycIdentityNotVerified => '身份未验证';

  @override
  String get kycAccountCompleteness => '账户完成度';

  @override
  String get kycYourAccount => '您的账户';

  @override
  String get kycIdentityVerification => '身份验证';

  @override
  String get kycAccountSecurity => '账户安全';

  @override
  String get kycDocumentPrivacyLabel => '证件隐私';

  @override
  String get kycSignIn => '登录';

  @override
  String get kycEditProfile => '编辑个人资料';

  @override
  String get kycVerifyEmail => '验证邮箱';

  @override
  String get kycVerifyPhoneNumber => '验证电话号码';

  @override
  String get kycBuyItems => '购买商品';

  @override
  String get kycSellItems => '出售商品';

  @override
  String get kycWithdrawFunds => '提现';

  @override
  String kycExpiresOnDate(String date) {
    return '于 $date 到期';
  }

  @override
  String get idViewDocument => '查看证件';

  @override
  String get idPreviewFailed => '无法打开此图片，请重试。';

  @override
  String get idFileInvalid =>
      '请选择有效的 JPG 或 PNG 图片，每边至少 100 像素，最多 2400 万像素且不超过 10 MB。';

  @override
  String get idFormInvalid => '请输入全名、13 位身份证号、有效日期，并提供卡片正反两面图片。';

  @override
  String get idSubmitted => '证件已提交审核。提交不代表身份验证已获批准。';

  @override
  String get idSaveFailed => '无法确认提交是否完成。请再次检查或重试同一提交。';

  @override
  String get idIntro => '请提交本人的国民身份证供审核，图片须清晰且四角完整可见。';

  @override
  String get idViewFront => '查看卡片正面';

  @override
  String get idViewBack => '查看卡片背面';

  @override
  String get idFullName => '卡片上的全名';

  @override
  String get idNumber => '国民身份证号（13 位）';

  @override
  String get idLifetime => '终身有效卡片（无到期日期）';

  @override
  String get idFileHelp => 'JPG/PNG，每张不超过 10 MB。图片私密保存，请保持此页面打开直至提交完成。';

  @override
  String get idSubmit => '提交审核';

  @override
  String get idRetrySubmission => '重试本次提交';

  @override
  String get idLegacyRecord => '已有证件记录，将保留原有流程。若无法打开图片，请联系支持人员。';

  @override
  String get reviewTitle => '审核身份证件';

  @override
  String get reviewQueueHelp => '显示最早的 50 项待审申请。审核后请刷新以加载后续申请。您不能审核自己的证件。';

  @override
  String get reviewLoadFailed => '无法加载申请，请检查审核权限后重试。';

  @override
  String get reviewEmpty => '没有可供您审核的申请。您自己的申请必须由其他审核人员处理。';

  @override
  String get reviewApprove => '批准申请';

  @override
  String get reviewReject => '拒绝并要求更正';

  @override
  String get reviewConfirm => '记录此决定吗？这将更新账户和证件状态，并创建审计记录。';

  @override
  String get reviewChecked => '我已检查所有必需图片、持有人信息、有效期及清晰度。';

  @override
  String get reviewReason => '审核备注／原因（拒绝时必填）';

  @override
  String get reviewActionFailed => '无法完成操作。拒绝原因至少需要 3 个字符。请刷新队列确认决定是否已保存。';

  @override
  String get issueLoadFailed => '无法加载您的 Kao ID，请重试。';

  @override
  String get issueActive => '有效';

  @override
  String get issueInactive => '此 Kao ID 当前不可用，请联系支持人员。';

  @override
  String get issueReady => '身份审核已批准，您可以申请 Kao ID。';

  @override
  String get issueAwaitingReview => '身份审核批准后，您才能使用 Kao ID。';

  @override
  String get issueRequest => '申请我的 Kao ID';

  @override
  String get issueFailed => '无法签发 Kao ID，请再次检查。批准和账户状态由服务器验证。';

  @override
  String get reviewNoPermission => '此账户没有有效的 KYC 审核权限。';

  @override
  String get reviewAlreadyDone => '此申请已经审核，请返回队列并刷新。';

  @override
  String get reviewUnavailable => '此申请不可用或属于您本人，请返回队列。';

  @override
  String get reviewMissingFiles => '缺少必要证明，请退回修改。';

  @override
  String get reviewInvalidDocument => '证件不完整、已过期或尚不具备批准条件，请检查详情。';

  @override
  String get reviewDuplicateDocument => '此证件号码已在其他账户获批，请转交管理员处理。';

  @override
  String get reviewReasonRequired => '请输入至少 3 个字符的拒绝原因。';

  @override
  String get idFirstName => '名（与身份证一致）';

  @override
  String get idLastName => '姓（与身份证一致）';

  @override
  String get idFirstNameRequired => '请输入您的名。';

  @override
  String get idLastNameRequired => '请输入您的姓。';

  @override
  String get idNameTooLong => '姓和名合计不得超过 200 个字符。';

  @override
  String get idNumberRequired => '请输入 13 位身份证号。';

  @override
  String get idIssuedRequired => '请选择签发日期。';

  @override
  String get idExpiryRequired => '请选择晚于签发日期的到期日期，或选择终身有效卡片。';

  @override
  String get idFrontRequired => '请选择身份证正面图片。';

  @override
  String get idBackRequired => '请选择身份证背面图片。';

  @override
  String get idCheckHighlightedFields => '证件未发送，请检查所列字段和图片。';

  @override
  String get idSubmitting => '正在提交证件，请稍候。';

  @override
  String get passportIntro => '请严格按护照填写信息，并附上清晰的个人信息页图片。';

  @override
  String get passportOtherPending => '您已有待审核的验证申请，请完成该申请后再提交其他证件。';

  @override
  String get passportCompleteForm => '证件未发送，请填写必填项、日期并提供护照图片。';

  @override
  String get passportRequired => '此项为必填项。';

  @override
  String get passportSingleName => '我的护照只有一个姓名（不区分姓和名）。';

  @override
  String get passportOnlyName => '与护照完全一致的姓名';

  @override
  String get passportGiven => '名（包括中间名）';

  @override
  String get passportFamily => '姓氏';

  @override
  String get passportFamilyFirst => '将姓显示在名前';

  @override
  String get passportIssuingCountry => '护照上的签发国家或机构';

  @override
  String get passportBirth => '出生日期';

  @override
  String get passportDatesInvalid => '请选择所有日期。签发日期不得早于出生日期，到期日期必须晚于签发日期。';

  @override
  String get passportSubmit => '提交护照审核';

  @override
  String get passportPendingHelp => '提交不等于批准。证件必须经过审核才能用于验证身份。';

  @override
  String get passportCountryInvalid => '请输入签发国家或机构的全称。';

  @override
  String get residenceIntro => '仅在您的情况需要时提交居留许可。请按证件填写信息。这是补充证明，不会自动批准身份验证。';

  @override
  String get residenceOtherPending => '您已有待审核的验证申请，请等待结果后再提交其他证件。';

  @override
  String get residenceCompleteForm => '证件未发送，请检查必填项、日期和图片。';

  @override
  String get residenceSingleName => '证件上仅有一个姓名。';

  @override
  String get residenceOnlyName => '证件上的姓名';

  @override
  String get residenceIssuingCountry => '签发国家或机构';

  @override
  String get residenceNumber => '居留许可号码';

  @override
  String get residenceNoExpiry => '证件未注明到期日期';

  @override
  String get residencePendingHelp => '提交居留许可不会确认身份或创建 Kao ID，需要授权人员审核。';

  @override
  String get residenceDatesInvalid => '请选择签发日期及晚于它的到期日期，或确认未注明有效期。';

  @override
  String get residenceSubmit => '提交居留许可审核';

  @override
  String get residenceCardFormat => '有正反面的卡片';

  @override
  String get residenceTwoSides => '请附上正反两面，包括背面的备注。';

  @override
  String get residenceOnePage => '单页证件：请附上完整页面。';

  @override
  String get residenceFront => '居留卡正面';

  @override
  String get residenceBack => '居留卡背面';

  @override
  String get residencePage => '完整居留许可页面';

  @override
  String get residenceViewFront => '查看正面／证件页';

  @override
  String get residenceViewBack => '查看背面';

  @override
  String get residenceImageRequired => '请选择此面或页面的图片。';

  @override
  String get bankSubmissionIntro =>
      '添加泰国个人银行账户（THB）以供审核。添加账户不代表验证通过，也不会启用支付功能。';

  @override
  String get bankPendingHelp => '此账户正在等待审核。请等待结果后再提交其他账户。银行审核与身份证件审核分开进行。';

  @override
  String get bankDuplicate => '此账户已存在，请刷新账户列表。';

  @override
  String get bankCompleteForm => '提交前请检查账户信息并附上证明材料。';

  @override
  String get bankEvidence => '银行账户证明材料';

  @override
  String get bankEvidenceHelp => '请附上能清楚显示银行名称、持有人姓名及账号的存折页或账户证明。仅可使用本人名下的账户。';

  @override
  String get bankViewEvidence => '查看已提交的证明材料';

  @override
  String get bankInstitutionName => '证件上的银行名称';

  @override
  String get bankHolderName => '银行文件上的账户持有人姓名';

  @override
  String get bankBranchOptional => '支行（选填）';

  @override
  String get bankAccountType => '账户类型';

  @override
  String get bankSavings => '储蓄账户';

  @override
  String get bankCurrent => '往来账户';

  @override
  String get bankNumberInvalid => '请输入 6–20 位数字，包括开头的零。';

  @override
  String get bankEvidenceRequired => '请附上银行账户证明材料。';

  @override
  String get bankSubmitReview => '提交账户审核';

  @override
  String get bankResubmitHelp => '可提交更正后的信息和证明材料重新审核，原记录会保留。';

  @override
  String get bankRetryHelp => '这些信息已保留以供重试。请重新提交或刷新列表，确认是否保存成功。';

  @override
  String get bankNoAccounts => '暂无银行账户';

  @override
  String get bankAddAccount => '添加银行账户';

  @override
  String get bankAccountNumber => '银行账号';

  @override
  String get adminMembersTitle => '用户账户管理';

  @override
  String get adminReadOnly => '查看会员信息。搜索操作将被记录。';

  @override
  String get adminSearchHint => '完整邮箱、账户 ID 或 Kao ID';

  @override
  String get adminSearch => '搜索';

  @override
  String get adminSearchEmpty => '未找到匹配的会员';

  @override
  String get adminAccessDenied => '您无权查看会员信息';

  @override
  String get adminUserId => '账户 ID';

  @override
  String get adminAccountState => '账户状态';

  @override
  String get adminIdentityState => 'Kao ID 状态';

  @override
  String get adminNotIssued => '尚未签发';

  @override
  String get adminActive => '正常';

  @override
  String get adminSuspended => '受限';

  @override
  String get adminClosed => '已关闭';

  @override
  String get staffActor => '操作人';

  @override
  String get staffAdmin => '管理员';

  @override
  String get staffAssign => '授予角色';

  @override
  String get staffAssignments => '工作人员列表';

  @override
  String get staffConfirm => '确认更改权限？授予角色不代表通过 KYC。';

  @override
  String get staffEmpty => '暂无记录';

  @override
  String get staffHelp => '只有 Owner 可以授予或撤销角色。新权限不设到期日，请在不再需要时撤销。';

  @override
  String get staffHistory => '权限变更记录';

  @override
  String get staffInactive => '未启用或已过期';

  @override
  String get staffKycRequired => '此角色要求通过 KYC 并拥有有效的 Kao ID。';

  @override
  String get staffLatest => '最近 100 条记录';

  @override
  String get staffNoExpiry => '直至撤销';

  @override
  String get staffPermissions => '权限代码';

  @override
  String get staffReviewScope =>
      '可审核其他账户的身份证、护照、居留证明及银行账户。仅通过居留证明或银行审核不会签发 Kao ID。';

  @override
  String get staffReviewer => 'KYC 审核员';

  @override
  String get staffRevoke => '撤销角色';

  @override
  String get staffRole => '角色';

  @override
  String get staffSuperAdmin => '超级管理员';

  @override
  String get staffSupport => '客服';

  @override
  String get staffTargetInvalid => '请选择已验证邮箱的正常账户。不能在此授予 Owner 角色。';

  @override
  String get staffTitle => '工作人员管理';

  @override
  String get reviewIdentityName => '已核实的身份姓名';

  @override
  String get reviewBankNameRequired => '请先通过身份审核。银行账户姓名必须与有效且已批准的身份证明一致。';

  @override
  String get adminHubTitle => 'Kao ID 管理中心';

  @override
  String get adminHubScope => '管理统一账户和身份验证。交易由 Secondhand 管理。';

  @override
  String get adminHubStaffHelp => '分配或撤销工作人员角色，并查看操作记录。';

  @override
  String get adminHubReviewHelp => '查看其他账户的证明材料并审核申请。不能审核自己的申请。';

  @override
  String get accountStateTitle => '统一账户状态';

  @override
  String get accountSuspend => '暂停账户';

  @override
  String get accountRestore => '恢复账户';

  @override
  String get accountStateHelp =>
      '限制资料修改和身份验证操作，保留现有 KYC 和 Kao ID。必须填写原因。暂停不等于注销账户或撤销 KYC。';

  @override
  String get accountStateFailed => '操作失败：可能无权限、账户受保护或状态已变更。请重新搜索账户后再试。';

  @override
  String get accountStateHistory => '最近50条状态记录';

  @override
  String get accountStateActor => '操作人';

  @override
  String get noticeTitle => '通知';

  @override
  String get noticeHelp => '显示最近30条通知。点击消息可标为已读。点击右侧打开按钮查看最新详情，系统将重新检查权限。';

  @override
  String get noticeEmpty => '暂无通知';

  @override
  String get noticeSubmitted => '已收到身份验证申请';

  @override
  String get noticeApproved => '身份验证申请已获批准';

  @override
  String get noticeRejected => '身份验证申请被拒绝，请查看历史记录中的原因。';

  @override
  String get noticeBankApproved => '银行账户已验证';

  @override
  String get noticeBankRejected => '银行账户审核被拒绝，请查看历史记录中的原因。';

  @override
  String get noticeSuspended => '账户操作已暂停';

  @override
  String get noticeRestored => '账户已恢复';

  @override
  String get noticeUpdated => '账户信息有更新';

  @override
  String get lifeTitle => '关闭账户与恢复使用';

  @override
  String get lifeHelp =>
      '提交申请不会立即关闭账户，等待处理期间可以取消。恢复原 Kao ID 需要验证身份，仅邮箱或电话号码相同并不足够。工作人员权限不会自动恢复。';

  @override
  String get lifeOwner => 'Owner 无法在此页面申请关闭账户。';

  @override
  String get lifeClose => '申请关闭账户';

  @override
  String get lifeRecover => '申请恢复使用';

  @override
  String get lifePending => '等待处理';

  @override
  String get lifeCancelled => '已取消';

  @override
  String get adminCopy => '复制';

  @override
  String get adminAccountCode => '账户参考编号';

  @override
  String get adminActorRole => '操作时的角色';

  @override
  String get adminOwner => '所有者';

  @override
  String get ownerRequests => '账户申请';

  @override
  String get ownerRequestsHelp => '查看关闭与恢复使用申请、原因及已记录的历史。';

  @override
  String get adminMore => '加载更多';

  @override
  String get lifeRejected => '申请已拒绝';

  @override
  String get lifeReject => '拒绝申请';

  @override
  String get lifeChecks => '账户检查';

  @override
  String get lifeChecksHelp => '以下数量来自当前数据表。总记录数不代表未结事项已处理完毕。';

  @override
  String get lifeOrders => '订单：总记录数';

  @override
  String get lifeDisputes => '争议：总记录数';

  @override
  String get lifeKycPending => '待审核身份申请';

  @override
  String get lifeWallet => '钱包：余额／冻结余额';

  @override
  String get lifeNoWallet => '没有钱包记录';

  @override
  String get lifeCloseBlocked => '暂不支持关闭账户。必须先完成会话终止及关联服务的检查。';

  @override
  String get lifeApproved => '申请已批准';

  @override
  String get closeAccountTitle => '账户已关闭';

  @override
  String get closeAccountHelp =>
      '此账户已关闭。原有Kao ID和身份记录将保留。您可以申请恢复使用，但使用权限和工作人员权限不会自动恢复。';

  @override
  String get closeSessionEnded => '此会话已结束。请退出并重新登录以查看账户状态。';

  @override
  String get closeAccountAction => '立即关闭账户';

  @override
  String get closeAccountConfirm =>
      '此操作将停止账户使用、终止现有会话、撤销工作人员权限并取消待审核的身份验证申请。原有Kao ID和历史记录将保留。请在审核申请后确认。';

  @override
  String get closeAccountReady => '当前条件检查已通过。确认时服务器将再次检查。';

  @override
  String get closeAccountBlocked =>
      '暂时无法关闭账户。请检查下方账户状态和服务记录。有服务记录不一定代表欠款。恢复使用申请需要单独进行身份审核。';

  @override
  String get closeServiceReview => '需要进一步审核的服务记录';

  @override
  String get recoveryEvidenceTitle => '验证身份以恢复使用';

  @override
  String get recoveryEvidenceHelp =>
      '请提交新的身份证或护照供工作人员审核。批准前账户仍保持关闭。原有Kao ID将保留，工作人员权限不会恢复。';

  @override
  String get recoveryActionFailed =>
      '操作未完成。请检查资料、有效期和会话后重试。如原有身份证明不可用，请联系Owner。';

  @override
  String get recoveryRetryHelp => '网络故障后请使用相同文件重试。如需更换已上传文件，请取消此申请并重新申请恢复使用。';

  @override
  String get recoveryReviewTitle => '账户恢复审核';

  @override
  String get recoveryReviewHelp =>
      '请比较新证据与保留的身份记录。批准后将恢复该账户及原有Kao ID，不会恢复工作人员权限。请记录认定为同一人的理由。';

  @override
  String get recoveryPreviousEvidence => '查看原有证据';

  @override
  String get recoveryConfirmPerson => '我已核实申请人的身份，并比较了可用的原有证据。';

  @override
  String get recoveryRestored => '账户使用已恢复';

  @override
  String get restrictedAccountHelp => '此账户已被限制，无法执行账户操作。请联系管理员核查。';

  @override
  String get unavailableAccountHelp => '账户信息不可用。请重试或退出登录。';

  @override
  String get sessionTitle => '已登录的会话';

  @override
  String get sessionHelp => '最多显示100个有效登录会话。浏览器和IP信息来自认证服务，缺失信息显示为 —。';

  @override
  String get sessionCurrent => '当前会话';

  @override
  String get sessionStarted => '登录时间';

  @override
  String get sessionRefreshed => '最近令牌刷新';

  @override
  String get sessionRevoke => '结束会话';

  @override
  String get sessionOthers => '结束所有其他会话';

  @override
  String get sessionConfirm => '相关会话需要重新登录。当前会话将保持有效。';

  @override
  String get documentHealthTitle => '证件有效性与续期';

  @override
  String get documentHealthHelp =>
      '可在到期前30天内、到期后或撤销后提交新证件。历史记录和原Kao ID保留，新证件需重新审核。';

  @override
  String get documentRevoke => '撤销证件审批';

  @override
  String get documentRevokeHelp =>
      '请记录原因。若不再有有效的主要身份证件，Kao ID将暂停使用，直到新证件获批。历史记录将保留。';

  @override
  String get documentRevoked => '审批已撤销';

  @override
  String get documentRenew => '打开证件／提交替换证件';

  @override
  String get documentHistory => '撤销与到期历史';

  @override
  String get documentSystem => '系统 · 证件到期检查';

  @override
  String get documentExpiring => '您的证件将在30天内到期，请准备替换证件。';

  @override
  String get walletTitle => '中央钱包';

  @override
  String get walletReadHelp => '查看已记录的余额和交易。充值和购物暂未开放。显示的余额不代表可用资金。';

  @override
  String get walletLoadFailed => '无法加载钱包数据，请重试。';

  @override
  String get walletMissing => '此账户尚未创建钱包。';

  @override
  String get walletRecorded => '已记录余额';

  @override
  String get walletHeld => '已记录冻结金额';

  @override
  String get walletStateCode => '状态代码';

  @override
  String get walletUpdated => '更新时间';

  @override
  String get walletHistory => '交易记录';

  @override
  String get walletNoTransactions => '暂无交易记录。';

  @override
  String get walletTypeCode => '交易类型代码';

  @override
  String get walletReference => '交易参考编号';

  @override
  String get walletAfter => '已记录交易后余额';

  @override
  String get walletMore => '加载更多';

  @override
  String get partnerTitle => '金融合作伙伴';

  @override
  String get partnerHelp => 'Owner 分别管理每个合作伙伴及其环境。批准本身不会启用连接或转移资金。';

  @override
  String get partnerFailed => '操作失败。权限或记录可能已更改，请重新加载并确认后重试。';

  @override
  String get partnerEmpty => '尚无已注册的合作伙伴。';

  @override
  String get partnerAdd => '注册合作伙伴';

  @override
  String get partnerSandbox => '测试模式';

  @override
  String get partnerLive => '正式模式';

  @override
  String get partnerPending => '待批准';

  @override
  String get partnerApproved => '已批准';

  @override
  String get partnerRejected => '已拒绝';

  @override
  String get partnerDisabled => '已停用';

  @override
  String get partnerApprove => '批准合作伙伴';

  @override
  String get partnerReject => '拒绝';

  @override
  String get partnerDisable => '停用连接';

  @override
  String get partnerResubmit => '重新申请审核';

  @override
  String get partnerEnable => '启用连接';

  @override
  String get partnerBalance => '查询余额';

  @override
  String get partnerPayment => '支付';

  @override
  String get partnerRefund => '退款';

  @override
  String get partnerPayout => '出款';

  @override
  String get partnerTopup => '充值';

  @override
  String get partnerReadiness => '适配器报告';

  @override
  String get partnerReady => '技术检查仍然有效';

  @override
  String get partnerNotReady => '尚未准备好连接，需要服务器配置和测试凭证';

  @override
  String get partnerConnected => '连接已启用';

  @override
  String get partnerNotConnected => '连接未启用';

  @override
  String get partnerCapabilities => '允许的服务';

  @override
  String get partnerExpires => '检查有效期至';

  @override
  String get partnerHistory => '最近20条历史记录';

  @override
  String get partnerActor => '操作人';

  @override
  String get partnerSystem => '系统';

  @override
  String get partnerFormHelp =>
      '请输入真实合作伙伴名称和唯一代码：2–40个小写英文字母、数字、_或-。请勿输入API密钥或密码。';

  @override
  String get partnerCode => '合作伙伴代码';

  @override
  String get partnerName => '合作伙伴名称';

  @override
  String get partnerConfirm => '请确认合作伙伴、环境和允许的服务。批准不会转移资金，启用前需提供技术检查报告。';

  @override
  String get partnerReason => '原因（至少3个字符）';

  @override
  String get carrierTitle => '物流合作伙伴';

  @override
  String get carrierQuote => '运费报价';

  @override
  String get carrierShipment => '创建运单';

  @override
  String get carrierTracking => '物流追踪';

  @override
  String get carrierCancel => '取消运单';

  @override
  String get linkedWalletTitle => '已关联的钱包';

  @override
  String get linkedWalletHelp => '余额来自提供方所示时间的报告。不同提供方及测试和正式资金分别显示。此页尚未开放付款。';

  @override
  String get linkedWalletEmpty => '暂无关联的合作伙伴钱包。';

  @override
  String get linkedReference => '提供方参考编号';

  @override
  String get linkedNoSnapshot => '尚未收到余额报告。';

  @override
  String get linkedAvailable => '提供方报告的可用余额';

  @override
  String get linkedPending => '提供方报告的处理中余额';

  @override
  String get linkedObserved => '提供方数据时间';

  @override
  String get linkedStale => '此报告已超过30分钟。刷新此页不会从提供方获取新余额。';

  @override
  String get linkedUnreconciled => '尚未完成与交易账本的对账。';

  @override
  String get linkedApplied => '余额报告已应用';

  @override
  String get linkedOlder => '旧报告已保留，未覆盖最新余额';

  @override
  String get mfaHelp => '使用身份验证器保护账户。不要向他人透露设置密钥或验证码。';

  @override
  String get mfaFailed => '无法完成操作。请检查密码或验证码，必要时重新验证MFA后重试。';

  @override
  String get mfaSessionVerified => '此会话已通过MFA。敏感操作需要在10分钟内完成验证。';

  @override
  String get mfaSessionRequired => '使用受保护的工具前，请验证身份验证器代码。';

  @override
  String get mfaFactorCount => '已验证的身份验证器';

  @override
  String get mfaChoose => '选择身份验证器';

  @override
  String get mfaManualSetup => '在验证器中添加基于时间的账户，名称设为Kao ID，输入此密钥，然后验证六位代码。';

  @override
  String get mfaShowSecret => '显示／隐藏设置密钥';

  @override
  String get mfaCode => '六位验证码';

  @override
  String get mfaVerify => '验证代码';

  @override
  String get mfaBackupHelp => '请在另一台设备添加备用验证器。添加前先通过现有验证器验证。';

  @override
  String get mfaDeviceName => '验证器名称';

  @override
  String get mfaAdd => '添加验证器';

  @override
  String get mfaRecoveryHelp =>
      '设备丢失时，请登录并使用备用验证器。若全部丢失，须由项目管理员进行身份恢复；仅凭邮箱不能重置管理权限。';

  @override
  String get securityEnable => '启用工作人员保护';

  @override
  String get securityEnableHelp =>
      'Owner需要两个已验证的验证器，另需两名已设置MFA的有效KYC审核员。启用后管理访问必须通过MFA，证件及身份恢复结果须由两名不同审核员一致确认。不能一键降低保护。';

  @override
  String get securityReadyReviewers => '已设置MFA的KYC审核员';

  @override
  String get securityEnabled => '工作人员保护已启用';

  @override
  String get securitySetupPending => '设置未完成，仍使用原审批规则';

  @override
  String get dualReviewHelp => '两名独立审核员达成一致后才会应用最终结果。';

  @override
  String get dualWaiting => '等待第二名审核员';

  @override
  String get dualFirstDecision => '第一名审核员的意见';

  @override
  String get dualOwnVote => '您已提交第一份意见，须由另一名有权限的审核员处理。';

  @override
  String get dualDisagreeHelp => '选择相反结果将退回重新审核，不会直接驳回申请。';

  @override
  String get securityNotice => '账户安全设置已更改';

  @override
  String get securityOperations => '安全运行监控';

  @override
  String get securityPendingReviews => '等待第二次审核';

  @override
  String get securityExpiredReviews => '审核确认已超时';

  @override
  String get securityFailedEmail => '失败的邮件任务';

  @override
  String get securityStalledEmail => '处理期限已过的邮件任务';

  @override
  String get securityPendingEmail => '待发送邮件任务';

  @override
  String get securityOperationsHelp => '实际队列数量，不代表邮件已送达或系统容量已验证。请刷新检查。';

  @override
  String get noticeReviewNew => '有新的待审核申请';

  @override
  String get noticeReviewSecond => '等待第二位审核员审核';

  @override
  String get noticeReviewRestart => '审核意见不一致，请重新审核';

  @override
  String get noticeRoleAssigned => '已分配工作人员角色';

  @override
  String get noticeRoleRevoked => '工作人员角色已失效或被撤销';

  @override
  String get noticeOpenItem => '打开相关项目';

  @override
  String get noticeCurrentStatus => '当前状态';

  @override
  String get noticeTargetUnavailable => '此项目已完成或当前无法审核。';

  @override
  String get noticeAccessFailed => '无法打开此项目。请检查网络、当前权限和多重身份验证，然后重试。';

  @override
  String get businessRegTitle => '注册企业';

  @override
  String get businessRegSubtitle => '只需验证一次，即可在所有 Kao 服务中使用您的企业。';

  @override
  String businessRegStepCounter(int current, int total) {
    return '第 $current 步，共 $total 步';
  }

  @override
  String get businessRegStepDetails => '企业信息';

  @override
  String get businessRegStepDocument => '企业文件';

  @override
  String get businessRegStepBank => '银行账户';

  @override
  String get businessRegStepReview => '核对并提交';

  @override
  String get businessRegSecureNotice => '您的信息已加密，仅用于验证您的企业。';

  @override
  String get businessRegDetailsHeading => '介绍一下您的企业';

  @override
  String get businessRegDetailsDescription => '请按照注册文件上的内容准确填写。';

  @override
  String get businessRegTypeLabel => '企业类型';

  @override
  String get businessRegTypeCompany => '公司或合伙企业';

  @override
  String get businessRegTypeCompanyHint => '拥有 13 位注册号的法人';

  @override
  String get businessRegTypeOrganization => '基金会或协会';

  @override
  String get businessRegTypeOrganizationHint => '已注册的非营利组织';

  @override
  String get businessRegNameLabel => '注册名称';

  @override
  String get businessRegNumberLabel => '注册号';

  @override
  String get businessRegNumberHelp => '仅限 13 位数字';

  @override
  String get businessRegCategoryLabel => '业务类别';

  @override
  String get businessRegCategoryRetail => '零售';

  @override
  String get businessRegCategoryFood => '餐饮';

  @override
  String get businessRegCategoryServices => '服务';

  @override
  String get businessRegCategoryTechnology => '科技';

  @override
  String get businessRegCategoryOther => '其他';

  @override
  String get businessRegDescriptionLabel => '企业简介（选填）';

  @override
  String get businessRegFieldRequired => '此项为必填项';

  @override
  String get businessRegNumberInvalid => '请输入 13 位注册号';

  @override
  String get businessRegDocumentHeading => '上传注册文件';

  @override
  String get businessRegDocumentDescription => '显示企业名称和注册号的公司证明或注册证书。';

  @override
  String get businessRegDocumentRequirements =>
      'JPG、PNG 或 PDF，不超过 10 MB，所有文字须清晰可读。';

  @override
  String get businessRegDocumentChoose => '选择文件';

  @override
  String get businessRegDocumentReplace => '更换文件';

  @override
  String get businessRegDocumentUploaded => '文件已上传';

  @override
  String get businessRegDocumentUploading => '正在安全上传…';

  @override
  String get businessRegDocumentMissing => '尚未上传文件';

  @override
  String get businessRegBankHeading => '收款银行账户';

  @override
  String get businessRegBankDescription => '企业收入将转入您 Kao ID 中已验证的银行账户。';

  @override
  String get businessRegBankApproved => '已验证';

  @override
  String get businessRegBankPending => '审核中';

  @override
  String get businessRegBankRejected => '未通过';

  @override
  String get businessRegBankMissing => '尚无已验证的银行账户';

  @override
  String get businessRegBankRequiredHelp => '银行账户验证通过后即可提交。';

  @override
  String get businessRegBankVerifyAction => '验证银行账户';

  @override
  String get businessRegBankCheckAgain => '重新检查';

  @override
  String get businessRegReviewHeading => '核对您的信息';

  @override
  String get businessRegReviewDescription => '请确认信息无误。审核期间无法编辑。';

  @override
  String get businessRegEdit => '编辑';

  @override
  String get businessRegConsent => '我确认以上信息准确无误，并同意 Kao ID 对其进行核验。';

  @override
  String get businessRegSubmit => '提交审核';

  @override
  String get businessRegContinue => '继续';

  @override
  String get businessRegBack => '返回';

  @override
  String get businessRegSubmitConfirmTitle => '确定提交注册申请？';

  @override
  String get businessRegSubmitConfirmBody => '我们将审核您的企业信息并通知您结果。';

  @override
  String get businessRegCancelDraft => '取消注册';

  @override
  String get businessRegCancelConfirmTitle => '确定取消此注册？';

  @override
  String get businessRegCancelConfirmBody => '草稿和已上传的文件将不再使用。';

  @override
  String get businessRegKeepEditing => '继续编辑';

  @override
  String get businessRegStatusReviewTitle => '正在审核您的企业';

  @override
  String get businessRegStatusReviewBody => '审核完成后我们会立即通知您。';

  @override
  String get businessRegStatusApprovedTitle => '您的企业已通过验证';

  @override
  String get businessRegStatusApprovedBody => '您现在可以在 Kao 服务中使用您的企业。';

  @override
  String get businessRegStatusRejectedTitle => '注册未获批准';

  @override
  String get businessRegStatusRejectedBody => '您可以使用更新后的信息重新注册。';

  @override
  String get businessRegStatusActionTitle => '需要您处理';

  @override
  String get businessRegStatusActionBody => '请查看通知了解需要更新的内容。';

  @override
  String get businessRegRefreshStatus => '刷新状态';

  @override
  String get businessRegStartNew => '重新注册';

  @override
  String get businessRegBackToAccount => '返回我的账户';

  @override
  String get businessRegErrorGeneric => '出现问题，请重试。';

  @override
  String get businessRegErrorSession => '会话已结束，请重新登录。';

  @override
  String get businessRegErrorRestricted => '您的账户目前无法注册企业。';

  @override
  String get businessRegErrorActiveExists => '您已有一项正在处理的注册申请。';

  @override
  String get businessRegErrorNotEditable => '此注册申请已无法更改。';

  @override
  String get businessRegErrorDocumentRequired => '请上传注册文件。';

  @override
  String get businessRegErrorBankRequired => '提交前需要一个已验证的银行账户。';

  @override
  String get businessRegErrorFile => '无法使用此文件。请选择不超过 10 MB 的 JPG、PNG 或 PDF。';

  @override
  String get businessRegErrorDuplicate => '此注册号已被注册。';

  @override
  String get businessRegHubDescription => '验证您的企业以开设店铺并接收款项。';

  @override
  String get businessReviewTitle => '企业审核';

  @override
  String get businessReviewHubHelp => '批准或拒绝其他账户的企业注册。批准后将签发 Business Kao ID。';

  @override
  String get businessReviewQueueHelp => '显示最早的 50 个待审核注册。您不能审核自己的注册。';

  @override
  String get businessReviewEmpty => '暂无待审核的企业注册。';

  @override
  String businessReviewSubmittedOn(String date) {
    return '提交于 $date';
  }

  @override
  String get businessReviewApplicant => '申请人';

  @override
  String get businessReviewOwnerKaoId => '个人 Kao ID';

  @override
  String get businessReviewOwnerName => '已验证姓名';

  @override
  String get businessReviewDescription => '企业简介';

  @override
  String get businessReviewBankName => '银行';

  @override
  String get businessReviewBankAccount => '账号';

  @override
  String businessReviewBankAccountEnding(String last4) {
    return '尾号 $last4';
  }

  @override
  String get businessReviewBankAccountName => '账户名';

  @override
  String get businessReviewNotAvailable => '无信息';

  @override
  String get businessReviewOpenDocument => '打开';

  @override
  String get businessReviewDocumentViewed => '已查看';

  @override
  String get businessReviewDecisionHeading => '审核决定';

  @override
  String get businessReviewChecked => '我已核实文件与企业名称、注册号和申请人一致。';

  @override
  String get businessReviewReason => '给申请人的备注（拒绝时必填）';

  @override
  String get businessReviewViewAllHint => '批准前请打开所有文件。';

  @override
  String get businessReviewApprove => '批准';

  @override
  String get businessReviewReject => '拒绝';

  @override
  String get businessReviewApproveConfirmTitle => '批准此企业？';

  @override
  String get businessReviewApproveConfirmBody =>
      '将签发 Business Kao ID 并通知申请人。此操作会记录在审计日志中。';

  @override
  String get businessReviewRejectConfirmTitle => '拒绝此注册？';

  @override
  String get businessReviewRejectConfirmBody => '申请人将看到您的备注，并可以重新提交注册。';

  @override
  String get businessReviewApprovedMessage => '企业已批准，Business Kao ID 已签发。';

  @override
  String get businessReviewRejectedMessage => '注册已拒绝，已通知申请人。';

  @override
  String get businessReviewAwaitingSecond => '已记录您的决定，需要另一位审核员确认。';

  @override
  String get businessReviewErrorDocumentMissing => '缺少注册文件。请拒绝，以便申请人重新上传。';

  @override
  String get businessReviewErrorDocumentOpen => '无法打开文件。请检查权限后重试。';

  @override
  String get businessReviewErrorOwnerKaoId => '申请人已无有效的个人 Kao ID，无法批准此企业。';

  @override
  String get businessReviewErrorOwnerBank => '申请人已验证的银行账户不再可用，无法批准此企业。';

  @override
  String get businessReviewErrorApplicantInactive => '申请人的账户未处于活跃状态，无法批准此企业。';

  @override
  String get noticeBusinessReviewNew => '有新的企业注册待审核';

  @override
  String get noticeBusinessReviewSecond => '企业注册等待第二位审核员';

  @override
  String get noticeBusinessReviewRestart => '审核员对企业注册意见不一致，请重新审核';

  @override
  String get noticeBusinessApproved => '您的企业已通过验证';

  @override
  String get noticeBusinessRejected => '企业注册未获批准，请查看原因。';

  @override
  String get businessRegStatusReasonLabel => '审核员备注';

  @override
  String get dashAccountInfoTitle => '账户信息';

  @override
  String get dashDetails => '详情';

  @override
  String get dashDisplayNameLabel => '显示名称';

  @override
  String dashKaoIdLine(String kaoId) {
    return 'Kao ID：$kaoId';
  }

  @override
  String get dashKaoIdPending => '完成全部验证后将发放 Kao ID';

  @override
  String get dashFinanceTitle => '资金';

  @override
  String get dashServicesTitle => '使用 Kao ID 的服务';

  @override
  String get dashSecondhandName => 'KaoSure Secondhand';

  @override
  String get dashBusinessName => '企业';

  @override
  String get dashServiceAvailable => '可使用';

  @override
  String get dashServiceOpen => '打开';

  @override
  String get dashBusinessRegister => '注册';

  @override
  String get dashNotRegistered => '未注册';

  @override
  String get dashDraft => '草稿';

  @override
  String get dashNotApproved => '未获批准';

  @override
  String get dashNotAdded => '未添加';

  @override
  String get dashLoadFailedShort => '无法加载';

  @override
  String get dashSecurityTitle => '登录与安全';

  @override
  String get dashSecurityDescription => '管理密码、两步验证和已登录的设备。';

  @override
  String get dashAdminCenter => '管理中心';
}

/// The translations for Chinese, using the Han script (`zh_Hans`).
class AppLocalizationsZhHans extends AppLocalizationsZh {
  AppLocalizationsZhHans() : super('zh_Hans');

  @override
  String get languageSystem => '跟随系统';

  @override
  String get languageSaveFailed => '无法保存语言，请重试。';

  @override
  String get appName => 'KaoSure';

  @override
  String get kaoId => 'Kao ID';

  @override
  String get settings => '设置';

  @override
  String get language => '语言';

  @override
  String get languageThai => '泰语';

  @override
  String get languageEnglish => '英语';

  @override
  String get languageChineseSimplified => '简体中文';

  @override
  String get languageJapanese => '日语';

  @override
  String get languageBurmese => '缅甸语';

  @override
  String get security => '安全';

  @override
  String get password => '密码';

  @override
  String get changePassword => '修改密码';

  @override
  String get cancel => '取消';

  @override
  String get save => '保存';

  @override
  String get continueLabel => '继续';

  @override
  String get back => '返回';

  @override
  String get notifications => '通知';

  @override
  String get notificationPreferencesDescription => '管理通知偏好';

  @override
  String get privacy => '隐私';

  @override
  String get privacyPermissionsDescription => '隐私与权限';

  @override
  String get aboutKaoId => '关于 Kao ID';

  @override
  String get aboutKaoIdDescription => '版本、许可证及法律信息';

  @override
  String get passwordChangeDescription => '修改您的密码';

  @override
  String get devices => '设备';

  @override
  String get trustedDevicesDescription => '管理可信设备';

  @override
  String get loginHistory => '登录历史';

  @override
  String get loginHistoryDescription => '近期登录活动';

  @override
  String get twoFactorAuthentication => '双因素认证';

  @override
  String get twoFactorDescription => '保护您的账户';

  @override
  String get services => '服务';

  @override
  String get marketplace => '交易市场';

  @override
  String get marketplaceDescription => '在 KaoSure 买卖商品';

  @override
  String get auction => '拍卖';

  @override
  String get auctionDescription => '商品拍卖';

  @override
  String get kaoPay => 'KaoPay';

  @override
  String get kaoPayDescription => '数字钱包';

  @override
  String get moreServices => '更多服务';

  @override
  String get moreServicesDescription => '探索 Kao Ecosystem 服务';

  @override
  String get serviceUnavailable => '暂未开放';

  @override
  String get quickActions => '快捷操作';

  @override
  String get profile => '个人资料';

  @override
  String get verifyIdentity => '验证身份';

  @override
  String get kaoCode => 'Kao Code';

  @override
  String get accountTitle => '我的账户';

  @override
  String get accountSecurity => '账户与安全';

  @override
  String get identityVerification => '身份验证';

  @override
  String get identityVerificationDescription => '验证身份以提高账户安全性';

  @override
  String get bankAccounts => '银行账户';

  @override
  String get bankAccountsDescription => '管理收款银行账户';

  @override
  String get accountDevicesDescription => '查看和管理已登录设备';

  @override
  String get accountSessions => '会话与登录';

  @override
  String get accountSessionsDescription => '查看登录活动';

  @override
  String get businessAccount => '企业账户';

  @override
  String get organizations => '公司／组织';

  @override
  String get organizationsDescription => '管理组织和访问权限';

  @override
  String get accountLanguageDescription => '管理 Kao ID 语言';

  @override
  String get accountNotificationsDescription => '管理 Kao ID 通知';

  @override
  String get retry => '重试';

  @override
  String get profileNotFound => '未找到个人资料';

  @override
  String get profileSaved => '个人资料已保存';

  @override
  String get editProfile => '编辑个人资料';

  @override
  String get kaoIdAvailableAfterVerification => '身份验证后可用';

  @override
  String get displayName => '显示名称';

  @override
  String get displayNameExample => '例如：KaoSure Official';

  @override
  String get profileSharedDescription => '您的显示名称和照片用于各项 Kao ID 服务，之后可以修改。';

  @override
  String get displayNameMinLength => '名称至少需要 3 个字符';

  @override
  String get displayNameMaxLength => '名称不得超过 30 个字符';

  @override
  String get profileVisibilityDescription => '您的头像和名称会显示在各项 Kao ID 服务中';

  @override
  String get editYourProfile => '编辑您的个人资料';

  @override
  String get profileDescription =>
      '您可以修改 Kao ID 的显示名称和头像。这些信息会显示在交易市场及其他 Kao Ecosystem 服务中。';

  @override
  String get profileDetails => '详情';

  @override
  String get accountVerified => '身份已验证';

  @override
  String get organizationAccount => '组织账户';

  @override
  String get accountRegistered => '已注册';

  @override
  String get accountStandard => '标准账户';

  @override
  String get completeProfile => '完善资料';

  @override
  String get completeYourProfile => '完善您的个人资料';

  @override
  String get completeProfileDescription => '设置您的 Kao ID 基本资料。';

  @override
  String get displayNameHint => '其他用户看到的名称';

  @override
  String get displayNameRequired => '请输入显示名称';

  @override
  String get displayNameTooLong => '显示名称不得超过 100 个字符';

  @override
  String get preferredLanguage => '首选语言';

  @override
  String get languageCodeHint => '例如：th 或 en';

  @override
  String get languageRequired => '请输入语言';

  @override
  String get saveProfile => '保存个人资料';

  @override
  String get profileLoadFailed => '无法加载个人资料，请重试。';

  @override
  String get profileSaveFailed => '无法保存个人资料，请重试。';

  @override
  String get kaoIdUser => 'Kao ID 用户';

  @override
  String get usernameNotSet => '尚未设置用户名';

  @override
  String accountCompletion(int percent) {
    return '账户完成度 $percent%';
  }

  @override
  String get dashboardLoadFailed => '无法加载账户，请重试。';

  @override
  String get homeLabel => '首页';

  @override
  String get homeIntroduction => '集中管理您的账户和安全设置。';

  @override
  String get viewProfile => '查看个人资料';

  @override
  String get identityEntryDescription => '通过 Kao ID 查看状态并继续身份验证。';

  @override
  String get viewIdentityStatus => '查看验证状态';

  @override
  String get governanceLabel => '管理后台';

  @override
  String get governanceDescription => '根据分配的权限管理平台';

  @override
  String get authLogin => '登录';

  @override
  String get authRegister => '注册';

  @override
  String get authCreateAccount => '创建账户';

  @override
  String get authEmail => '电子邮箱';

  @override
  String get authEmailHint => '请输入电子邮箱';

  @override
  String get authEmailRequired => '请输入电子邮箱';

  @override
  String get authEmailInvalid => '请输入有效的电子邮箱地址';

  @override
  String get authPasswordHint => '请输入密码';

  @override
  String get authPasswordRequired => '请输入密码';

  @override
  String get authPasswordMinLength => '至少使用 8 个字符';

  @override
  String get authPasswordNumberRequired => '至少包含一个数字';

  @override
  String get authPasswordSpecialRequired => '至少包含一个特殊字符';

  @override
  String get authConfirmPassword => '确认密码';

  @override
  String get authConfirmPasswordHint => '请再次输入密码';

  @override
  String get authConfirmPasswordRequired => '请确认密码';

  @override
  String get authPasswordMismatch => '两次密码不一致';

  @override
  String get authForgotPassword => '忘记密码';

  @override
  String get authForgotPasswordLink => '忘记密码？';

  @override
  String get authExistingAccount => '已有账户？登录';

  @override
  String get authRegistrationSucceeded => '账户已创建';

  @override
  String get authSendResetLink => '发送重置链接';

  @override
  String get authResetLinkSent => '如果此邮箱可用于恢复账户，您将收到重置链接。';

  @override
  String get authVerifyEmail => '验证邮箱';

  @override
  String get authVerificationEmailSent => '验证邮件已发送';

  @override
  String get authEmailNotVerified => '邮箱尚未验证';

  @override
  String get authEmailVerified => '邮箱已验证';

  @override
  String get authVerifyEmailInstructions => '打开验证邮件并点击链接。如果找不到邮件，可以请求重新发送。';

  @override
  String get authResendVerificationEmail => '重新发送验证邮件';

  @override
  String get authCheckAgain => '再次检查';

  @override
  String get authVerifyLater => '稍后验证';

  @override
  String get authNewPassword => '新密码';

  @override
  String get authNewPasswordHint => '请输入新密码';

  @override
  String get authNewPasswordRequired => '请输入新密码';

  @override
  String get authConfirmNewPassword => '确认新密码';

  @override
  String get authConfirmNewPasswordHint => '请再次输入新密码';

  @override
  String get authConfirmNewPasswordRequired => '请确认新密码';

  @override
  String get authResetPassword => '重置密码';

  @override
  String get authPasswordChanged => '密码已修改';

  @override
  String get authInvalidRecoveryLink => '此密码重置链接无效或已过期';

  @override
  String get authInvalidRecoveryDescription => '请请求新的重置链接以确认密码修改。';

  @override
  String get authRequestNewLink => '请求新链接';

  @override
  String get authVerificationCodeSent => '验证码已发送';

  @override
  String get authSendCodeFailed => '无法发送验证码，请重试。';

  @override
  String get authChangePasswordFailed => '无法修改密码，请检查验证码后重试。';

  @override
  String get authVerificationCodeRequired => '请输入验证码';

  @override
  String get authReauthenticateTitle => '修改密码前验证';

  @override
  String get authReauthenticateDescription => '为保障安全，我们将向账户中已验证的邮箱或电话号码发送验证码。';

  @override
  String get authSendCode => '发送验证码';

  @override
  String get authVerificationCode => '验证码';

  @override
  String get authVerificationCodeHint => '请输入收到的验证码';

  @override
  String get authSending => '正在发送…';

  @override
  String get authResendCode => '重新发送验证码';

  @override
  String get authRequirementsTitle => '密码要求：';

  @override
  String get authRequirementLength => '至少 8 个字符';

  @override
  String get authRequirementNumber => '一个数字';

  @override
  String get authRequirementSpecial => '一个特殊字符';

  @override
  String get authWelcome => '欢迎使用 Kao ID';

  @override
  String get authLoginFailed => '无法登录，请检查信息后重试。';

  @override
  String get authRegistrationFailed => '无法创建账户，请检查信息后重试。';

  @override
  String get authResetRequestFailed => '无法请求重置链接，请重试。';

  @override
  String get authVerificationFailed => '无法检查邮箱验证状态或重新发送验证邮件，请重试。';

  @override
  String get authResetFailed => '无法重置密码，请重试或请求新链接。';

  @override
  String get authShowPassword => '显示密码';

  @override
  String get authHidePassword => '隐藏密码';

  @override
  String get authBootstrapFailed => '无法打开账户，请重试。';

  @override
  String get signOut => '退出登录';

  @override
  String get signOutConfirmation => '确定退出登录吗？';

  @override
  String get signOutFailed => '无法退出登录，请重试。';

  @override
  String get kycLoadFailed => '无法加载验证信息，请重试。';

  @override
  String get kycInformation => '验证信息';

  @override
  String get kycInformationDescription => '管理您的身份验证信息和证件。';

  @override
  String get kycPermissions => '访问权限';

  @override
  String get kycPermissionsDescription => '您的访问权限取决于验证状态。';

  @override
  String get accountHubIntroduction => '按类别管理您的账户。';

  @override
  String get personalDetailsTitle => '个人信息';

  @override
  String get personalDetailsDescription => '查看和编辑显示名称及头像。';

  @override
  String get securityHubDescription => '管理账户密码。';

  @override
  String get settingsHubDescription => '选择语言和退出登录。';

  @override
  String get openSectionLabel => '打开此项';

  @override
  String get kycHubIntro => '按类别管理联系信息验证和身份证件。';

  @override
  String get kycContactGroup => '联系信息验证';

  @override
  String get kycDocumentsGroup => '身份证件';

  @override
  String get kycOtherGroup => '补充信息';

  @override
  String get kycEmailTitle => '电子邮箱';

  @override
  String get kycPhoneTitle => '电话号码';

  @override
  String get kycIdCardTitle => '国民身份证';

  @override
  String get kycPassportTitle => '护照';

  @override
  String get kycResidenceTitle => '居留许可';

  @override
  String get kycBankTitle => '银行账户';

  @override
  String get kycHistoryTitle => '验证历史';

  @override
  String get kycUnknownStatus => '无法获取状态';

  @override
  String get kycVerifiedStatus => '已验证';

  @override
  String get kycUnverifiedStatus => '未验证';

  @override
  String get kycPendingStatus => '审核中';

  @override
  String get kycRejectedStatus => '未获批准';

  @override
  String get kycExpiredStatus => '已过期';

  @override
  String get kycCancelledStatus => '已取消';

  @override
  String get kycNoRequest => '暂无验证申请';

  @override
  String get kycRequestTitle => '最新申请';

  @override
  String get kycHistoryDescription => '查看审核结果和状态变更。';

  @override
  String get kycHistoryEmpty => '暂无验证历史。';

  @override
  String get kycHistoryFailed => '无法加载验证历史，请重试。';

  @override
  String get kycHistoryEvent => '验证更新';

  @override
  String get kycActionApprove => '验证已批准';

  @override
  String get kycActionReject => '验证已拒绝';

  @override
  String get kycActionReview => '已开始审核';

  @override
  String get kycActionSubmit => '已提交验证';

  @override
  String get kycActionCancel => '申请已取消';

  @override
  String get kycResidenceLimited => '查看已有信息，暂不支持上传';

  @override
  String get kycRequestFailed => '无法提交申请，请重试。';

  @override
  String get contactPhoneInvalid => '请输入泰国手机号码，或以 + 开头的国际号码。';

  @override
  String get contactOtpInvalid => '请输入收到的 6–10 位验证码。';

  @override
  String get contactOtpFailed => '无法验证验证码，可能有误或已过期，请重试。';

  @override
  String get contactSendFailed => '无法发送验证码，请稍后重试。';

  @override
  String get contactStillPending => '新号码尚未确认，请再次检查。';

  @override
  String get contactSessionChanged => '登录账户已变更，请重新打开此页面。';

  @override
  String get contactLoadFailed => '无法加载您的信息，请再次检查。';

  @override
  String get contactPhoneIntro => '确认此号码能接收验证码。新号码仅在服务器验证后生效。';

  @override
  String get contactNoPhone => '未登记电话号码';

  @override
  String get contactPhoneFormat => '例如：0812345678 或 +66812345678';

  @override
  String get contactWait => '请稍候再发送';

  @override
  String get contactSendCode => '发送验证码';

  @override
  String get contactCodeDestination => '验证码已发送至';

  @override
  String get contactOtpLabel => '验证码';

  @override
  String get contactVerifyCode => '验证代码';

  @override
  String get contactExpiryHelp => '请使用最新收到的验证码。如果过期，请在按钮可用后重新请求。';

  @override
  String get contactEmailRefreshHelp => '打开邮件链接后，请返回此处再次检查。如果链接过期，请请求新邮件。';

  @override
  String get changeEmailTitle => '更改邮箱地址';

  @override
  String get changePhoneTitle => '更改电话号码';

  @override
  String get changeContactIntro => '确认密码以申请变更。在新联系方式确认前，原联系方式继续有效。';

  @override
  String get changeContactCurrent => '当前联系方式';

  @override
  String get changeContactPending => '等待确认';

  @override
  String get changeEmailPending => '请打开确认邮件。您可能需要确认当前和新的两个邮箱，然后选择“再次检查”。';

  @override
  String get changeEmailNew => '新邮箱地址';

  @override
  String get changePhoneNew => '新电话号码';

  @override
  String get changeContactPassword => '当前密码';

  @override
  String get changeContactPasswordHelp =>
      '请使用 Kao ID 密码。如果仅通过外部服务登录且没有密码，请先通过账户恢复设置密码。';

  @override
  String get changeContactRequest => '申请变更／重新发送确认';

  @override
  String get changeContactDone => '新联系方式已确认。';

  @override
  String get changeContactSame => '请输入不同的邮箱地址或电话号码。';

  @override
  String get changeEmailInvalid => '请输入有效的邮箱地址。';

  @override
  String get changeContactPasswordRequired => '请输入当前密码。';

  @override
  String get changeContactFailed =>
      '无法完成申请。请检查密码和验证码，等待规定时间后重试。再次申请变更前请先检查当前状态。';

  @override
  String get changeContactMfaRequired => '请输入已登记的身份验证器应用中的代码。';

  @override
  String get changeContactMfaDevice => '身份验证器';

  @override
  String get changeContactMfaCode => '身份验证器代码';

  @override
  String get kycNationalIdCard => '国民身份证';

  @override
  String get kycUseYourNationalIdCardFor => '使用国民身份证进行身份验证。';

  @override
  String get kycChooseFrontImage => '选择正面图片';

  @override
  String get kycChooseBackImage => '选择背面图片';

  @override
  String get kycFrontImageSelected => '已选择正面图片';

  @override
  String get kycBackImageSelected => '已选择背面图片';

  @override
  String get kycVerifyWithYourNationalIdCard => '使用国民身份证验证';

  @override
  String get kycUseYourOriginalIdCardMake => '请使用身份证原件，确保所有信息清晰可见且无反光。';

  @override
  String get kycDocumentRequirements => '证件要求';

  @override
  String get kycBothSidesMustBeClear => '正反两面均须清晰';

  @override
  String get kycIncludeAllInformationOnTheCard => '包含卡片上的所有信息';

  @override
  String get kycAvoidGlareAndBlurredImages => '避免反光和模糊';

  @override
  String get kycDocumentsAreUsedForIdentityVerification => '证件用于身份验证';

  @override
  String get kycSubmitIdentityDocumentsOnlyThroughKao => '请仅通过 Kao ID 提交身份证件。';

  @override
  String get kycPassport => '护照';

  @override
  String get kycAddYourPassportInformationForIdentity => '添加护照信息以验证身份';

  @override
  String get kycPassportNumber => '护照号码';

  @override
  String get kycEnterTheNumberPrintedOnYour => '请输入护照上印制的号码';

  @override
  String get kycForExampleAa => '例如：AA1234567';

  @override
  String get kycEnterYourPassportNumber => '请输入护照号码';

  @override
  String get kycInvalidPassportNumber => '护照号码无效';

  @override
  String get kycDocumentDates => '证件日期';

  @override
  String get kycPassportIssueAndExpiryDates => '护照签发日期和有效期';

  @override
  String get kycIssueDate => '签发日期';

  @override
  String get kycExpiryDate => '到期日期';

  @override
  String get kycPassportDocument => '护照证件';

  @override
  String get kycChooseAClearImageOfThe => '请选择清晰的护照个人信息页图片';

  @override
  String get kycAddPassportImage => '添加护照图片';

  @override
  String get kycTapToSelectAFileFrom => '点击从设备选择文件';

  @override
  String get kycFileSelectedNotSubmittedYet => '已选择文件，尚未提交';

  @override
  String get kycChangeFile => '更换文件';

  @override
  String get kycDocumentPrivacy => '证件隐私';

  @override
  String get kycDocumentsAreUsedForIdentityVerification32 =>
      '证件用于身份验证。选择文件并不代表提交。';

  @override
  String get kycSaving => '正在保存…';

  @override
  String get kycSavePassport => '保存护照';

  @override
  String get kycSelectBothIssueAndExpiryDates => '请选择签发日期和到期日期';

  @override
  String get kycExpiryDateMustBeAfterIssue => '到期日期必须晚于签发日期';

  @override
  String get kycSelectAPassportImage => '请选择护照图片';

  @override
  String get kycPleaseSignInAgain => '请重新登录';

  @override
  String get kycPassportSaved => '护照已保存';

  @override
  String get kycSelectDate => '选择日期';

  @override
  String get kycResidencePermit => '居留许可';

  @override
  String get kycAResidencePermitIsUsedTo => '居留许可用于验证您的居留资格。';

  @override
  String get kycStatus => '状态';

  @override
  String get kycNoResidencePermitAdded => '尚未添加居留许可';

  @override
  String get kycUploadResidencePermit => '上传居留许可';

  @override
  String get kycFrontOfCard => '卡片正面';

  @override
  String get kycBackOfCard => '卡片背面';

  @override
  String get kycToday => '今天';

  @override
  String get kycYouCanChooseAnotherFileTo => '可以选择其他文件替换当前选择';

  @override
  String get kycSelected => '已选择';

  @override
  String get kycUploadRequirements => '上传要求';

  @override
  String get kycCheckTheInformationBeforeSubmitting => '提交前请检查信息';

  @override
  String get kycChooseImagesOfBothSidesOf => '请选择国民身份证正反两面的图片';

  @override
  String get kycJpgAndPngSupported => '支持 JPG 和 PNG';

  @override
  String get kycCheckThatTheImageIsClear => '选择前请确认图片清晰';

  @override
  String get kycSelectingAFileDoesNotUpload => '选择文件不会上传或提交文件';

  @override
  String get kycFileName => '文件名';

  @override
  String get kycFileSize => '文件大小';

  @override
  String get kycUploadedOn => '上传日期';

  @override
  String get kycChooseDocument => '选择证件';

  @override
  String get kycTapToSelectAFileFrom61 => '点击从设备选择文件';

  @override
  String get kycChooseFile => '选择文件';

  @override
  String get kycProcessing => '正在处理…';

  @override
  String get kycCheckThatTheImageIsClear64 => '选择前请确认图片清晰';

  @override
  String get kycSelectingAFileDoesNotUpload65 => '选择文件不会上传或提交文件';

  @override
  String get kycApproved => '已批准';

  @override
  String get kycAwaitingReview => '等待审核';

  @override
  String get kycRejected => '已拒绝';

  @override
  String get kycNoDocumentSubmitted => '尚未提交证件';

  @override
  String get kycBankAccount => '银行账户';

  @override
  String get kycAddingBankAccountsIsNotAvailable => '暂不支持添加银行账户';

  @override
  String get kycManagingBankAccountsIsNotAvailable => '暂不支持管理银行账户';

  @override
  String get kycBankAccountVerification => '银行账户验证';

  @override
  String get kycViewBankAccountVerificationForKao =>
      '查看 Kao Ecosystem 服务的银行账户验证情况';

  @override
  String get kycCheckAccountStatusAndItsMatch => '检查账户状态及其与 KYC 信息是否一致';

  @override
  String get kycLoadingBankAccountDetails => '正在加载银行账户信息…';

  @override
  String get kycCouldNotLoadTheDetails => '无法加载信息';

  @override
  String get kycTryAgain => '重试';

  @override
  String get kycNoBankAccountAdded => '尚未添加银行账户';

  @override
  String get kycBankAccountRegistrationIsNotAvailable => '银行账户登记暂未开放。';

  @override
  String get kycAddBankAccount => '添加银行账户';

  @override
  String get kycAccountHolderName => '账户持有人姓名';

  @override
  String get kycPrimaryAccount => '主要账户';

  @override
  String get kycAccountNumber => '账户号码';

  @override
  String get kycVerificationStatus => '验证状态';

  @override
  String get kycNameMatchWithKyc => '姓名与 KYC 信息匹配情况';

  @override
  String get kycRejectionReason => '拒绝原因';

  @override
  String get kycVerifiedBankAccount => '已验证的银行账户';

  @override
  String get kycSecurity => '安全';

  @override
  String get kycTheAccountIsVerifiedAndIts => '账户已验证，持有人姓名与已验证身份一致';

  @override
  String get kycTheAccountHolderNameMustMatch => '账户持有人姓名须与已验证身份一致，才能认定为可信账户';

  @override
  String get kycCheckAgain => '再次检查';

  @override
  String get kycManageBankAccount => '管理银行账户';

  @override
  String get kycVerified => '已验证';

  @override
  String get kycTheBankAccountHasBeenVerified => '银行账户已验证';

  @override
  String get kycUnderReview => '审核中';

  @override
  String get kycTheBankAccountIsBeingReviewed => '银行账户正在审核中';

  @override
  String get kycAdditionalReview => '补充审核';

  @override
  String get kycFurtherReviewIsRequired => '需要进一步审核';

  @override
  String get kycNotVerified => '未验证';

  @override
  String get kycTheBankAccountDidNotPass => '银行账户未通过验证';

  @override
  String get kycExpired => '已过期';

  @override
  String get kycTheBankAccountVerificationHasExpired => '银行账户验证已过期';

  @override
  String get kycVerificationNotStarted => '尚未开始验证';

  @override
  String get kycTheBankAccountHasNotEntered => '银行账户尚未进入验证流程';

  @override
  String get kycAccountNameMatchesKyc => '账户姓名与 KYC 信息一致';

  @override
  String get kycTheAccountHolderNameMatchesThe => '账户持有人姓名与已验证身份一致';

  @override
  String get kycAccountNameDoesNotMatchKyc => '账户姓名与 KYC 信息不一致';

  @override
  String get kycTheAccountHolderNameDiffersFrom => '账户持有人姓名与已验证身份不同';

  @override
  String get kycReviewingAccountName => '正在审核账户姓名';

  @override
  String get kycMoreInformationMustBeReviewedBefore => '作出决定前需审核更多信息';

  @override
  String get kycAwaitingNameCheck => '等待姓名核查';

  @override
  String get kycTheAccountHolderNameWillBe => '将根据 KYC 信息核查账户持有人姓名';

  @override
  String get kycDocumentSaveFailed => '无法保存证件，请重试。';

  @override
  String get contactVerifiedHelp => '此联系方式已验证，可以在下方申请变更。';

  @override
  String get kycRejectedLabel => '已拒绝';

  @override
  String get kycNotAdded => '未添加';

  @override
  String get kycExpiryDateNotProvided => '未提供到期日期';

  @override
  String get kycSelectPassportExpiryDate => '选择护照到期日期';

  @override
  String get kycCancel => '取消';

  @override
  String get kycSelect => '选择';

  @override
  String get kycNoBankAccountAddedLabel => '尚未添加银行账户';

  @override
  String get kycAdditionalReviewLabel => '补充审核';

  @override
  String get kycNotVerifiedLabel => '未验证';

  @override
  String get kycNameMatchesKyc => '姓名与 KYC 信息一致';

  @override
  String get kycNameDoesNotMatch => '姓名不一致';

  @override
  String get kycAdditionalNameReview => '姓名补充审核';

  @override
  String get kycAwaitingKycNameCheck => '等待 KYC 姓名核查';

  @override
  String get kycVerifiedLabel => '已验证';

  @override
  String get kycVerificationHistory => '验证历史';

  @override
  String get kycReviewVerificationResultsAndChanges => '查看验证结果和变更';

  @override
  String get kycIdentityVerificationProgress => '身份验证进度';

  @override
  String get kycYourIdentityVerificationIsComplete => '您的身份验证已完成';

  @override
  String get kycVerifyAdditionalInformationToCompleteYourIdentity =>
      '验证补充信息以完成身份验证';

  @override
  String get kycVerificationComplete => '验证完成';

  @override
  String get kycInProgress => '进行中';

  @override
  String get kycChooseAnotherFile => '选择其他文件';

  @override
  String get kycEmail => '电子邮箱';

  @override
  String get kycNotVerifiedLabelText => '未验证';

  @override
  String get kycPhoneNumber => '电话号码';

  @override
  String get kycInformationRecorded => '信息已记录';

  @override
  String get kycAccessPermissions => '访问权限';

  @override
  String get kycIdentityVerified => '身份已验证';

  @override
  String get kycIdentityNotVerified => '身份未验证';

  @override
  String get kycAccountCompleteness => '账户完成度';

  @override
  String get kycYourAccount => '您的账户';

  @override
  String get kycIdentityVerification => '身份验证';

  @override
  String get kycAccountSecurity => '账户安全';

  @override
  String get kycDocumentPrivacyLabel => '证件隐私';

  @override
  String get kycSignIn => '登录';

  @override
  String get kycEditProfile => '编辑个人资料';

  @override
  String get kycVerifyEmail => '验证邮箱';

  @override
  String get kycVerifyPhoneNumber => '验证电话号码';

  @override
  String get kycBuyItems => '购买商品';

  @override
  String get kycSellItems => '出售商品';

  @override
  String get kycWithdrawFunds => '提现';

  @override
  String kycExpiresOnDate(String date) {
    return '于 $date 到期';
  }

  @override
  String get idViewDocument => '查看证件';

  @override
  String get idPreviewFailed => '无法打开此图片，请重试。';

  @override
  String get idFileInvalid =>
      '请选择有效的 JPG 或 PNG 图片，每边至少 100 像素，最多 2400 万像素且不超过 10 MB。';

  @override
  String get idFormInvalid => '请输入全名、13 位身份证号、有效日期，并提供卡片正反两面图片。';

  @override
  String get idSubmitted => '证件已提交审核。提交不代表身份验证已获批准。';

  @override
  String get idSaveFailed => '无法确认提交是否完成。请再次检查或重试同一提交。';

  @override
  String get idIntro => '请提交本人的国民身份证供审核，图片须清晰且四角完整可见。';

  @override
  String get idViewFront => '查看卡片正面';

  @override
  String get idViewBack => '查看卡片背面';

  @override
  String get idFullName => '卡片上的全名';

  @override
  String get idNumber => '国民身份证号（13 位）';

  @override
  String get idLifetime => '终身有效卡片（无到期日期）';

  @override
  String get idFileHelp => 'JPG/PNG，每张不超过 10 MB。图片私密保存，请保持此页面打开直至提交完成。';

  @override
  String get idSubmit => '提交审核';

  @override
  String get idRetrySubmission => '重试本次提交';

  @override
  String get idLegacyRecord => '已有证件记录，将保留原有流程。若无法打开图片，请联系支持人员。';

  @override
  String get reviewTitle => '审核身份证件';

  @override
  String get reviewQueueHelp => '显示最早的 50 项待审申请。审核后请刷新以加载后续申请。您不能审核自己的证件。';

  @override
  String get reviewLoadFailed => '无法加载申请，请检查审核权限后重试。';

  @override
  String get reviewEmpty => '没有可供您审核的申请。您自己的申请必须由其他审核人员处理。';

  @override
  String get reviewApprove => '批准申请';

  @override
  String get reviewReject => '拒绝并要求更正';

  @override
  String get reviewConfirm => '记录此决定吗？这将更新账户和证件状态，并创建审计记录。';

  @override
  String get reviewChecked => '我已检查所有必需图片、持有人信息、有效期及清晰度。';

  @override
  String get reviewReason => '审核备注／原因（拒绝时必填）';

  @override
  String get reviewActionFailed => '无法完成操作。拒绝原因至少需要 3 个字符。请刷新队列确认决定是否已保存。';

  @override
  String get issueLoadFailed => '无法加载您的 Kao ID，请重试。';

  @override
  String get issueActive => '有效';

  @override
  String get issueInactive => '此 Kao ID 当前不可用，请联系支持人员。';

  @override
  String get issueReady => '身份审核已批准，您可以申请 Kao ID。';

  @override
  String get issueAwaitingReview => '身份审核批准后，您才能使用 Kao ID。';

  @override
  String get issueRequest => '申请我的 Kao ID';

  @override
  String get issueFailed => '无法签发 Kao ID，请再次检查。批准和账户状态由服务器验证。';

  @override
  String get reviewNoPermission => '此账户没有有效的 KYC 审核权限。';

  @override
  String get reviewAlreadyDone => '此申请已经审核，请返回队列并刷新。';

  @override
  String get reviewUnavailable => '此申请不可用或属于您本人，请返回队列。';

  @override
  String get reviewMissingFiles => '缺少必要证明，请退回修改。';

  @override
  String get reviewInvalidDocument => '证件不完整、已过期或尚不具备批准条件，请检查详情。';

  @override
  String get reviewDuplicateDocument => '此证件号码已在其他账户获批，请转交管理员处理。';

  @override
  String get reviewReasonRequired => '请输入至少 3 个字符的拒绝原因。';

  @override
  String get idFirstName => '名（与身份证一致）';

  @override
  String get idLastName => '姓（与身份证一致）';

  @override
  String get idFirstNameRequired => '请输入您的名。';

  @override
  String get idLastNameRequired => '请输入您的姓。';

  @override
  String get idNameTooLong => '姓和名合计不得超过 200 个字符。';

  @override
  String get idNumberRequired => '请输入 13 位身份证号。';

  @override
  String get idIssuedRequired => '请选择签发日期。';

  @override
  String get idExpiryRequired => '请选择晚于签发日期的到期日期，或选择终身有效卡片。';

  @override
  String get idFrontRequired => '请选择身份证正面图片。';

  @override
  String get idBackRequired => '请选择身份证背面图片。';

  @override
  String get idCheckHighlightedFields => '证件未发送，请检查所列字段和图片。';

  @override
  String get idSubmitting => '正在提交证件，请稍候。';

  @override
  String get passportIntro => '请严格按护照填写信息，并附上清晰的个人信息页图片。';

  @override
  String get passportOtherPending => '您已有待审核的验证申请，请完成该申请后再提交其他证件。';

  @override
  String get passportCompleteForm => '证件未发送，请填写必填项、日期并提供护照图片。';

  @override
  String get passportRequired => '此项为必填项。';

  @override
  String get passportSingleName => '我的护照只有一个姓名（不区分姓和名）。';

  @override
  String get passportOnlyName => '与护照完全一致的姓名';

  @override
  String get passportGiven => '名（包括中间名）';

  @override
  String get passportFamily => '姓氏';

  @override
  String get passportFamilyFirst => '将姓显示在名前';

  @override
  String get passportIssuingCountry => '护照上的签发国家或机构';

  @override
  String get passportBirth => '出生日期';

  @override
  String get passportDatesInvalid => '请选择所有日期。签发日期不得早于出生日期，到期日期必须晚于签发日期。';

  @override
  String get passportSubmit => '提交护照审核';

  @override
  String get passportPendingHelp => '提交不等于批准。证件必须经过审核才能用于验证身份。';

  @override
  String get passportCountryInvalid => '请输入签发国家或机构的全称。';

  @override
  String get residenceIntro => '仅在您的情况需要时提交居留许可。请按证件填写信息。这是补充证明，不会自动批准身份验证。';

  @override
  String get residenceOtherPending => '您已有待审核的验证申请，请等待结果后再提交其他证件。';

  @override
  String get residenceCompleteForm => '证件未发送，请检查必填项、日期和图片。';

  @override
  String get residenceSingleName => '证件上仅有一个姓名。';

  @override
  String get residenceOnlyName => '证件上的姓名';

  @override
  String get residenceIssuingCountry => '签发国家或机构';

  @override
  String get residenceNumber => '居留许可号码';

  @override
  String get residenceNoExpiry => '证件未注明到期日期';

  @override
  String get residencePendingHelp => '提交居留许可不会确认身份或创建 Kao ID，需要授权人员审核。';

  @override
  String get residenceDatesInvalid => '请选择签发日期及晚于它的到期日期，或确认未注明有效期。';

  @override
  String get residenceSubmit => '提交居留许可审核';

  @override
  String get residenceCardFormat => '有正反面的卡片';

  @override
  String get residenceTwoSides => '请附上正反两面，包括背面的备注。';

  @override
  String get residenceOnePage => '单页证件：请附上完整页面。';

  @override
  String get residenceFront => '居留卡正面';

  @override
  String get residenceBack => '居留卡背面';

  @override
  String get residencePage => '完整居留许可页面';

  @override
  String get residenceViewFront => '查看正面／证件页';

  @override
  String get residenceViewBack => '查看背面';

  @override
  String get residenceImageRequired => '请选择此面或页面的图片。';

  @override
  String get bankSubmissionIntro =>
      '添加泰国个人银行账户（THB）以供审核。添加账户不代表验证通过，也不会启用支付功能。';

  @override
  String get bankPendingHelp => '此账户正在等待审核。请等待结果后再提交其他账户。银行审核与身份证件审核分开进行。';

  @override
  String get bankDuplicate => '此账户已存在，请刷新账户列表。';

  @override
  String get bankCompleteForm => '提交前请检查账户信息并附上证明材料。';

  @override
  String get bankEvidence => '银行账户证明材料';

  @override
  String get bankEvidenceHelp => '请附上能清楚显示银行名称、持有人姓名及账号的存折页或账户证明。仅可使用本人名下的账户。';

  @override
  String get bankViewEvidence => '查看已提交的证明材料';

  @override
  String get bankInstitutionName => '证件上的银行名称';

  @override
  String get bankHolderName => '银行文件上的账户持有人姓名';

  @override
  String get bankBranchOptional => '支行（选填）';

  @override
  String get bankAccountType => '账户类型';

  @override
  String get bankSavings => '储蓄账户';

  @override
  String get bankCurrent => '往来账户';

  @override
  String get bankNumberInvalid => '请输入 6–20 位数字，包括开头的零。';

  @override
  String get bankEvidenceRequired => '请附上银行账户证明材料。';

  @override
  String get bankSubmitReview => '提交账户审核';

  @override
  String get bankResubmitHelp => '可提交更正后的信息和证明材料重新审核，原记录会保留。';

  @override
  String get bankRetryHelp => '这些信息已保留以供重试。请重新提交或刷新列表，确认是否保存成功。';

  @override
  String get bankNoAccounts => '暂无银行账户';

  @override
  String get bankAddAccount => '添加银行账户';

  @override
  String get bankAccountNumber => '银行账号';

  @override
  String get adminMembersTitle => '用户账户管理';

  @override
  String get adminReadOnly => '查看会员信息。搜索操作将被记录。';

  @override
  String get adminSearchHint => '完整邮箱、账户 ID 或 Kao ID';

  @override
  String get adminSearch => '搜索';

  @override
  String get adminSearchEmpty => '未找到匹配的会员';

  @override
  String get adminAccessDenied => '您无权查看会员信息';

  @override
  String get adminUserId => '账户 ID';

  @override
  String get adminAccountState => '账户状态';

  @override
  String get adminIdentityState => 'Kao ID 状态';

  @override
  String get adminNotIssued => '尚未签发';

  @override
  String get adminActive => '正常';

  @override
  String get adminSuspended => '受限';

  @override
  String get adminClosed => '已关闭';

  @override
  String get staffActor => '操作人';

  @override
  String get staffAdmin => '管理员';

  @override
  String get staffAssign => '授予角色';

  @override
  String get staffAssignments => '工作人员列表';

  @override
  String get staffConfirm => '确认更改权限？授予角色不代表通过 KYC。';

  @override
  String get staffEmpty => '暂无记录';

  @override
  String get staffHelp => '只有 Owner 可以授予或撤销角色。新权限不设到期日，请在不再需要时撤销。';

  @override
  String get staffHistory => '权限变更记录';

  @override
  String get staffInactive => '未启用或已过期';

  @override
  String get staffKycRequired => '此角色要求通过 KYC 并拥有有效的 Kao ID。';

  @override
  String get staffLatest => '最近 100 条记录';

  @override
  String get staffNoExpiry => '直至撤销';

  @override
  String get staffPermissions => '权限代码';

  @override
  String get staffReviewScope =>
      '可审核其他账户的身份证、护照、居留证明及银行账户。仅通过居留证明或银行审核不会签发 Kao ID。';

  @override
  String get staffReviewer => 'KYC 审核员';

  @override
  String get staffRevoke => '撤销角色';

  @override
  String get staffRole => '角色';

  @override
  String get staffSuperAdmin => '超级管理员';

  @override
  String get staffSupport => '客服';

  @override
  String get staffTargetInvalid => '请选择已验证邮箱的正常账户。不能在此授予 Owner 角色。';

  @override
  String get staffTitle => '工作人员管理';

  @override
  String get reviewIdentityName => '已核实的身份姓名';

  @override
  String get reviewBankNameRequired => '请先通过身份审核。银行账户姓名必须与有效且已批准的身份证明一致。';

  @override
  String get adminHubTitle => 'Kao ID 管理中心';

  @override
  String get adminHubScope => '管理统一账户和身份验证。交易由 Secondhand 管理。';

  @override
  String get adminHubStaffHelp => '分配或撤销工作人员角色，并查看操作记录。';

  @override
  String get adminHubReviewHelp => '查看其他账户的证明材料并审核申请。不能审核自己的申请。';

  @override
  String get accountStateTitle => '统一账户状态';

  @override
  String get accountSuspend => '暂停账户';

  @override
  String get accountRestore => '恢复账户';

  @override
  String get accountStateHelp =>
      '限制资料修改和身份验证操作，保留现有 KYC 和 Kao ID。必须填写原因。暂停不等于注销账户或撤销 KYC。';

  @override
  String get accountStateFailed => '操作失败：可能无权限、账户受保护或状态已变更。请重新搜索账户后再试。';

  @override
  String get accountStateHistory => '最近50条状态记录';

  @override
  String get accountStateActor => '操作人';

  @override
  String get noticeTitle => '通知';

  @override
  String get noticeHelp => '显示最近30条通知。点击消息可标为已读。点击右侧打开按钮查看最新详情，系统将重新检查权限。';

  @override
  String get noticeEmpty => '暂无通知';

  @override
  String get noticeSubmitted => '已收到身份验证申请';

  @override
  String get noticeApproved => '身份验证申请已获批准';

  @override
  String get noticeRejected => '身份验证申请被拒绝，请查看历史记录中的原因。';

  @override
  String get noticeBankApproved => '银行账户已验证';

  @override
  String get noticeBankRejected => '银行账户审核被拒绝，请查看历史记录中的原因。';

  @override
  String get noticeSuspended => '账户操作已暂停';

  @override
  String get noticeRestored => '账户已恢复';

  @override
  String get noticeUpdated => '账户信息有更新';

  @override
  String get lifeTitle => '关闭账户与恢复使用';

  @override
  String get lifeHelp =>
      '提交申请不会立即关闭账户，等待处理期间可以取消。恢复原 Kao ID 需要验证身份，仅邮箱或电话号码相同并不足够。工作人员权限不会自动恢复。';

  @override
  String get lifeOwner => 'Owner 无法在此页面申请关闭账户。';

  @override
  String get lifeClose => '申请关闭账户';

  @override
  String get lifeRecover => '申请恢复使用';

  @override
  String get lifePending => '等待处理';

  @override
  String get lifeCancelled => '已取消';

  @override
  String get adminCopy => '复制';

  @override
  String get adminAccountCode => '账户参考编号';

  @override
  String get adminActorRole => '操作时的角色';

  @override
  String get adminOwner => '所有者';

  @override
  String get ownerRequests => '账户申请';

  @override
  String get ownerRequestsHelp => '查看关闭与恢复使用申请、原因及已记录的历史。';

  @override
  String get adminMore => '加载更多';

  @override
  String get lifeRejected => '申请已拒绝';

  @override
  String get lifeReject => '拒绝申请';

  @override
  String get lifeChecks => '账户检查';

  @override
  String get lifeChecksHelp => '以下数量来自当前数据表。总记录数不代表未结事项已处理完毕。';

  @override
  String get lifeOrders => '订单：总记录数';

  @override
  String get lifeDisputes => '争议：总记录数';

  @override
  String get lifeKycPending => '待审核身份申请';

  @override
  String get lifeWallet => '钱包：余额／冻结余额';

  @override
  String get lifeNoWallet => '没有钱包记录';

  @override
  String get lifeCloseBlocked => '暂不支持关闭账户。必须先完成会话终止及关联服务的检查。';

  @override
  String get lifeApproved => '申请已批准';

  @override
  String get closeAccountTitle => '账户已关闭';

  @override
  String get closeAccountHelp =>
      '此账户已关闭。原有Kao ID和身份记录将保留。您可以申请恢复使用，但使用权限和工作人员权限不会自动恢复。';

  @override
  String get closeSessionEnded => '此会话已结束。请退出并重新登录以查看账户状态。';

  @override
  String get closeAccountAction => '立即关闭账户';

  @override
  String get closeAccountConfirm =>
      '此操作将停止账户使用、终止现有会话、撤销工作人员权限并取消待审核的身份验证申请。原有Kao ID和历史记录将保留。请在审核申请后确认。';

  @override
  String get closeAccountReady => '当前条件检查已通过。确认时服务器将再次检查。';

  @override
  String get closeAccountBlocked =>
      '暂时无法关闭账户。请检查下方账户状态和服务记录。有服务记录不一定代表欠款。恢复使用申请需要单独进行身份审核。';

  @override
  String get closeServiceReview => '需要进一步审核的服务记录';

  @override
  String get recoveryEvidenceTitle => '验证身份以恢复使用';

  @override
  String get recoveryEvidenceHelp =>
      '请提交新的身份证或护照供工作人员审核。批准前账户仍保持关闭。原有Kao ID将保留，工作人员权限不会恢复。';

  @override
  String get recoveryActionFailed =>
      '操作未完成。请检查资料、有效期和会话后重试。如原有身份证明不可用，请联系Owner。';

  @override
  String get recoveryRetryHelp => '网络故障后请使用相同文件重试。如需更换已上传文件，请取消此申请并重新申请恢复使用。';

  @override
  String get recoveryReviewTitle => '账户恢复审核';

  @override
  String get recoveryReviewHelp =>
      '请比较新证据与保留的身份记录。批准后将恢复该账户及原有Kao ID，不会恢复工作人员权限。请记录认定为同一人的理由。';

  @override
  String get recoveryPreviousEvidence => '查看原有证据';

  @override
  String get recoveryConfirmPerson => '我已核实申请人的身份，并比较了可用的原有证据。';

  @override
  String get recoveryRestored => '账户使用已恢复';

  @override
  String get restrictedAccountHelp => '此账户已被限制，无法执行账户操作。请联系管理员核查。';

  @override
  String get unavailableAccountHelp => '账户信息不可用。请重试或退出登录。';

  @override
  String get sessionTitle => '已登录的会话';

  @override
  String get sessionHelp => '最多显示100个有效登录会话。浏览器和IP信息来自认证服务，缺失信息显示为 —。';

  @override
  String get sessionCurrent => '当前会话';

  @override
  String get sessionStarted => '登录时间';

  @override
  String get sessionRefreshed => '最近令牌刷新';

  @override
  String get sessionRevoke => '结束会话';

  @override
  String get sessionOthers => '结束所有其他会话';

  @override
  String get sessionConfirm => '相关会话需要重新登录。当前会话将保持有效。';

  @override
  String get documentHealthTitle => '证件有效性与续期';

  @override
  String get documentHealthHelp =>
      '可在到期前30天内、到期后或撤销后提交新证件。历史记录和原Kao ID保留，新证件需重新审核。';

  @override
  String get documentRevoke => '撤销证件审批';

  @override
  String get documentRevokeHelp =>
      '请记录原因。若不再有有效的主要身份证件，Kao ID将暂停使用，直到新证件获批。历史记录将保留。';

  @override
  String get documentRevoked => '审批已撤销';

  @override
  String get documentRenew => '打开证件／提交替换证件';

  @override
  String get documentHistory => '撤销与到期历史';

  @override
  String get documentSystem => '系统 · 证件到期检查';

  @override
  String get documentExpiring => '您的证件将在30天内到期，请准备替换证件。';

  @override
  String get walletTitle => '中央钱包';

  @override
  String get walletReadHelp => '查看已记录的余额和交易。充值和购物暂未开放。显示的余额不代表可用资金。';

  @override
  String get walletLoadFailed => '无法加载钱包数据，请重试。';

  @override
  String get walletMissing => '此账户尚未创建钱包。';

  @override
  String get walletRecorded => '已记录余额';

  @override
  String get walletHeld => '已记录冻结金额';

  @override
  String get walletStateCode => '状态代码';

  @override
  String get walletUpdated => '更新时间';

  @override
  String get walletHistory => '交易记录';

  @override
  String get walletNoTransactions => '暂无交易记录。';

  @override
  String get walletTypeCode => '交易类型代码';

  @override
  String get walletReference => '交易参考编号';

  @override
  String get walletAfter => '已记录交易后余额';

  @override
  String get walletMore => '加载更多';

  @override
  String get partnerTitle => '金融合作伙伴';

  @override
  String get partnerHelp => 'Owner 分别管理每个合作伙伴及其环境。批准本身不会启用连接或转移资金。';

  @override
  String get partnerFailed => '操作失败。权限或记录可能已更改，请重新加载并确认后重试。';

  @override
  String get partnerEmpty => '尚无已注册的合作伙伴。';

  @override
  String get partnerAdd => '注册合作伙伴';

  @override
  String get partnerSandbox => '测试模式';

  @override
  String get partnerLive => '正式模式';

  @override
  String get partnerPending => '待批准';

  @override
  String get partnerApproved => '已批准';

  @override
  String get partnerRejected => '已拒绝';

  @override
  String get partnerDisabled => '已停用';

  @override
  String get partnerApprove => '批准合作伙伴';

  @override
  String get partnerReject => '拒绝';

  @override
  String get partnerDisable => '停用连接';

  @override
  String get partnerResubmit => '重新申请审核';

  @override
  String get partnerEnable => '启用连接';

  @override
  String get partnerBalance => '查询余额';

  @override
  String get partnerPayment => '支付';

  @override
  String get partnerRefund => '退款';

  @override
  String get partnerPayout => '出款';

  @override
  String get partnerTopup => '充值';

  @override
  String get partnerReadiness => '适配器报告';

  @override
  String get partnerReady => '技术检查仍然有效';

  @override
  String get partnerNotReady => '尚未准备好连接，需要服务器配置和测试凭证';

  @override
  String get partnerConnected => '连接已启用';

  @override
  String get partnerNotConnected => '连接未启用';

  @override
  String get partnerCapabilities => '允许的服务';

  @override
  String get partnerExpires => '检查有效期至';

  @override
  String get partnerHistory => '最近20条历史记录';

  @override
  String get partnerActor => '操作人';

  @override
  String get partnerSystem => '系统';

  @override
  String get partnerFormHelp =>
      '请输入真实合作伙伴名称和唯一代码：2–40个小写英文字母、数字、_或-。请勿输入API密钥或密码。';

  @override
  String get partnerCode => '合作伙伴代码';

  @override
  String get partnerName => '合作伙伴名称';

  @override
  String get partnerConfirm => '请确认合作伙伴、环境和允许的服务。批准不会转移资金，启用前需提供技术检查报告。';

  @override
  String get partnerReason => '原因（至少3个字符）';

  @override
  String get carrierTitle => '物流合作伙伴';

  @override
  String get carrierQuote => '运费报价';

  @override
  String get carrierShipment => '创建运单';

  @override
  String get carrierTracking => '物流追踪';

  @override
  String get carrierCancel => '取消运单';

  @override
  String get linkedWalletTitle => '已关联的钱包';

  @override
  String get linkedWalletHelp => '余额来自提供方所示时间的报告。不同提供方及测试和正式资金分别显示。此页尚未开放付款。';

  @override
  String get linkedWalletEmpty => '暂无关联的合作伙伴钱包。';

  @override
  String get linkedReference => '提供方参考编号';

  @override
  String get linkedNoSnapshot => '尚未收到余额报告。';

  @override
  String get linkedAvailable => '提供方报告的可用余额';

  @override
  String get linkedPending => '提供方报告的处理中余额';

  @override
  String get linkedObserved => '提供方数据时间';

  @override
  String get linkedStale => '此报告已超过30分钟。刷新此页不会从提供方获取新余额。';

  @override
  String get linkedUnreconciled => '尚未完成与交易账本的对账。';

  @override
  String get linkedApplied => '余额报告已应用';

  @override
  String get linkedOlder => '旧报告已保留，未覆盖最新余额';

  @override
  String get mfaHelp => '使用身份验证器保护账户。不要向他人透露设置密钥或验证码。';

  @override
  String get mfaFailed => '无法完成操作。请检查密码或验证码，必要时重新验证MFA后重试。';

  @override
  String get mfaSessionVerified => '此会话已通过MFA。敏感操作需要在10分钟内完成验证。';

  @override
  String get mfaSessionRequired => '使用受保护的工具前，请验证身份验证器代码。';

  @override
  String get mfaFactorCount => '已验证的身份验证器';

  @override
  String get mfaChoose => '选择身份验证器';

  @override
  String get mfaManualSetup => '在验证器中添加基于时间的账户，名称设为Kao ID，输入此密钥，然后验证六位代码。';

  @override
  String get mfaShowSecret => '显示／隐藏设置密钥';

  @override
  String get mfaCode => '六位验证码';

  @override
  String get mfaVerify => '验证代码';

  @override
  String get mfaBackupHelp => '请在另一台设备添加备用验证器。添加前先通过现有验证器验证。';

  @override
  String get mfaDeviceName => '验证器名称';

  @override
  String get mfaAdd => '添加验证器';

  @override
  String get mfaRecoveryHelp =>
      '设备丢失时，请登录并使用备用验证器。若全部丢失，须由项目管理员进行身份恢复；仅凭邮箱不能重置管理权限。';

  @override
  String get securityEnable => '启用工作人员保护';

  @override
  String get securityEnableHelp =>
      'Owner需要两个已验证的验证器，另需两名已设置MFA的有效KYC审核员。启用后管理访问必须通过MFA，证件及身份恢复结果须由两名不同审核员一致确认。不能一键降低保护。';

  @override
  String get securityReadyReviewers => '已设置MFA的KYC审核员';

  @override
  String get securityEnabled => '工作人员保护已启用';

  @override
  String get securitySetupPending => '设置未完成，仍使用原审批规则';

  @override
  String get dualReviewHelp => '两名独立审核员达成一致后才会应用最终结果。';

  @override
  String get dualWaiting => '等待第二名审核员';

  @override
  String get dualFirstDecision => '第一名审核员的意见';

  @override
  String get dualOwnVote => '您已提交第一份意见，须由另一名有权限的审核员处理。';

  @override
  String get dualDisagreeHelp => '选择相反结果将退回重新审核，不会直接驳回申请。';

  @override
  String get securityNotice => '账户安全设置已更改';

  @override
  String get securityOperations => '安全运行监控';

  @override
  String get securityPendingReviews => '等待第二次审核';

  @override
  String get securityExpiredReviews => '审核确认已超时';

  @override
  String get securityFailedEmail => '失败的邮件任务';

  @override
  String get securityStalledEmail => '处理期限已过的邮件任务';

  @override
  String get securityPendingEmail => '待发送邮件任务';

  @override
  String get securityOperationsHelp => '实际队列数量，不代表邮件已送达或系统容量已验证。请刷新检查。';

  @override
  String get noticeReviewNew => '有新的待审核申请';

  @override
  String get noticeReviewSecond => '等待第二位审核员审核';

  @override
  String get noticeReviewRestart => '审核意见不一致，请重新审核';

  @override
  String get noticeRoleAssigned => '已分配工作人员角色';

  @override
  String get noticeRoleRevoked => '工作人员角色已失效或被撤销';

  @override
  String get noticeOpenItem => '打开相关项目';

  @override
  String get noticeCurrentStatus => '当前状态';

  @override
  String get noticeTargetUnavailable => '此项目已完成或当前无法审核。';

  @override
  String get noticeAccessFailed => '无法打开此项目。请检查网络、当前权限和多重身份验证，然后重试。';

  @override
  String get businessRegTitle => '注册企业';

  @override
  String get businessRegSubtitle => '只需验证一次，即可在所有 Kao 服务中使用您的企业。';

  @override
  String businessRegStepCounter(int current, int total) {
    return '第 $current 步，共 $total 步';
  }

  @override
  String get businessRegStepDetails => '企业信息';

  @override
  String get businessRegStepDocument => '企业文件';

  @override
  String get businessRegStepBank => '银行账户';

  @override
  String get businessRegStepReview => '核对并提交';

  @override
  String get businessRegSecureNotice => '您的信息已加密，仅用于验证您的企业。';

  @override
  String get businessRegDetailsHeading => '介绍一下您的企业';

  @override
  String get businessRegDetailsDescription => '请按照注册文件上的内容准确填写。';

  @override
  String get businessRegTypeLabel => '企业类型';

  @override
  String get businessRegTypeCompany => '公司或合伙企业';

  @override
  String get businessRegTypeCompanyHint => '拥有 13 位注册号的法人';

  @override
  String get businessRegTypeOrganization => '基金会或协会';

  @override
  String get businessRegTypeOrganizationHint => '已注册的非营利组织';

  @override
  String get businessRegNameLabel => '注册名称';

  @override
  String get businessRegNumberLabel => '注册号';

  @override
  String get businessRegNumberHelp => '仅限 13 位数字';

  @override
  String get businessRegCategoryLabel => '业务类别';

  @override
  String get businessRegCategoryRetail => '零售';

  @override
  String get businessRegCategoryFood => '餐饮';

  @override
  String get businessRegCategoryServices => '服务';

  @override
  String get businessRegCategoryTechnology => '科技';

  @override
  String get businessRegCategoryOther => '其他';

  @override
  String get businessRegDescriptionLabel => '企业简介（选填）';

  @override
  String get businessRegFieldRequired => '此项为必填项';

  @override
  String get businessRegNumberInvalid => '请输入 13 位注册号';

  @override
  String get businessRegDocumentHeading => '上传注册文件';

  @override
  String get businessRegDocumentDescription => '显示企业名称和注册号的公司证明或注册证书。';

  @override
  String get businessRegDocumentRequirements =>
      'JPG、PNG 或 PDF，不超过 10 MB，所有文字须清晰可读。';

  @override
  String get businessRegDocumentChoose => '选择文件';

  @override
  String get businessRegDocumentReplace => '更换文件';

  @override
  String get businessRegDocumentUploaded => '文件已上传';

  @override
  String get businessRegDocumentUploading => '正在安全上传…';

  @override
  String get businessRegDocumentMissing => '尚未上传文件';

  @override
  String get businessRegBankHeading => '收款银行账户';

  @override
  String get businessRegBankDescription => '企业收入将转入您 Kao ID 中已验证的银行账户。';

  @override
  String get businessRegBankApproved => '已验证';

  @override
  String get businessRegBankPending => '审核中';

  @override
  String get businessRegBankRejected => '未通过';

  @override
  String get businessRegBankMissing => '尚无已验证的银行账户';

  @override
  String get businessRegBankRequiredHelp => '银行账户验证通过后即可提交。';

  @override
  String get businessRegBankVerifyAction => '验证银行账户';

  @override
  String get businessRegBankCheckAgain => '重新检查';

  @override
  String get businessRegReviewHeading => '核对您的信息';

  @override
  String get businessRegReviewDescription => '请确认信息无误。审核期间无法编辑。';

  @override
  String get businessRegEdit => '编辑';

  @override
  String get businessRegConsent => '我确认以上信息准确无误，并同意 Kao ID 对其进行核验。';

  @override
  String get businessRegSubmit => '提交审核';

  @override
  String get businessRegContinue => '继续';

  @override
  String get businessRegBack => '返回';

  @override
  String get businessRegSubmitConfirmTitle => '确定提交注册申请？';

  @override
  String get businessRegSubmitConfirmBody => '我们将审核您的企业信息并通知您结果。';

  @override
  String get businessRegCancelDraft => '取消注册';

  @override
  String get businessRegCancelConfirmTitle => '确定取消此注册？';

  @override
  String get businessRegCancelConfirmBody => '草稿和已上传的文件将不再使用。';

  @override
  String get businessRegKeepEditing => '继续编辑';

  @override
  String get businessRegStatusReviewTitle => '正在审核您的企业';

  @override
  String get businessRegStatusReviewBody => '审核完成后我们会立即通知您。';

  @override
  String get businessRegStatusApprovedTitle => '您的企业已通过验证';

  @override
  String get businessRegStatusApprovedBody => '您现在可以在 Kao 服务中使用您的企业。';

  @override
  String get businessRegStatusRejectedTitle => '注册未获批准';

  @override
  String get businessRegStatusRejectedBody => '您可以使用更新后的信息重新注册。';

  @override
  String get businessRegStatusActionTitle => '需要您处理';

  @override
  String get businessRegStatusActionBody => '请查看通知了解需要更新的内容。';

  @override
  String get businessRegRefreshStatus => '刷新状态';

  @override
  String get businessRegStartNew => '重新注册';

  @override
  String get businessRegBackToAccount => '返回我的账户';

  @override
  String get businessRegErrorGeneric => '出现问题，请重试。';

  @override
  String get businessRegErrorSession => '会话已结束，请重新登录。';

  @override
  String get businessRegErrorRestricted => '您的账户目前无法注册企业。';

  @override
  String get businessRegErrorActiveExists => '您已有一项正在处理的注册申请。';

  @override
  String get businessRegErrorNotEditable => '此注册申请已无法更改。';

  @override
  String get businessRegErrorDocumentRequired => '请上传注册文件。';

  @override
  String get businessRegErrorBankRequired => '提交前需要一个已验证的银行账户。';

  @override
  String get businessRegErrorFile => '无法使用此文件。请选择不超过 10 MB 的 JPG、PNG 或 PDF。';

  @override
  String get businessRegErrorDuplicate => '此注册号已被注册。';

  @override
  String get businessRegHubDescription => '验证您的企业以开设店铺并接收款项。';

  @override
  String get businessReviewTitle => '企业审核';

  @override
  String get businessReviewHubHelp => '批准或拒绝其他账户的企业注册。批准后将签发 Business Kao ID。';

  @override
  String get businessReviewQueueHelp => '显示最早的 50 个待审核注册。您不能审核自己的注册。';

  @override
  String get businessReviewEmpty => '暂无待审核的企业注册。';

  @override
  String businessReviewSubmittedOn(String date) {
    return '提交于 $date';
  }

  @override
  String get businessReviewApplicant => '申请人';

  @override
  String get businessReviewOwnerKaoId => '个人 Kao ID';

  @override
  String get businessReviewOwnerName => '已验证姓名';

  @override
  String get businessReviewDescription => '企业简介';

  @override
  String get businessReviewBankName => '银行';

  @override
  String get businessReviewBankAccount => '账号';

  @override
  String businessReviewBankAccountEnding(String last4) {
    return '尾号 $last4';
  }

  @override
  String get businessReviewBankAccountName => '账户名';

  @override
  String get businessReviewNotAvailable => '无信息';

  @override
  String get businessReviewOpenDocument => '打开';

  @override
  String get businessReviewDocumentViewed => '已查看';

  @override
  String get businessReviewDecisionHeading => '审核决定';

  @override
  String get businessReviewChecked => '我已核实文件与企业名称、注册号和申请人一致。';

  @override
  String get businessReviewReason => '给申请人的备注（拒绝时必填）';

  @override
  String get businessReviewViewAllHint => '批准前请打开所有文件。';

  @override
  String get businessReviewApprove => '批准';

  @override
  String get businessReviewReject => '拒绝';

  @override
  String get businessReviewApproveConfirmTitle => '批准此企业？';

  @override
  String get businessReviewApproveConfirmBody =>
      '将签发 Business Kao ID 并通知申请人。此操作会记录在审计日志中。';

  @override
  String get businessReviewRejectConfirmTitle => '拒绝此注册？';

  @override
  String get businessReviewRejectConfirmBody => '申请人将看到您的备注，并可以重新提交注册。';

  @override
  String get businessReviewApprovedMessage => '企业已批准，Business Kao ID 已签发。';

  @override
  String get businessReviewRejectedMessage => '注册已拒绝，已通知申请人。';

  @override
  String get businessReviewAwaitingSecond => '已记录您的决定，需要另一位审核员确认。';

  @override
  String get businessReviewErrorDocumentMissing => '缺少注册文件。请拒绝，以便申请人重新上传。';

  @override
  String get businessReviewErrorDocumentOpen => '无法打开文件。请检查权限后重试。';

  @override
  String get businessReviewErrorOwnerKaoId => '申请人已无有效的个人 Kao ID，无法批准此企业。';

  @override
  String get businessReviewErrorOwnerBank => '申请人已验证的银行账户不再可用，无法批准此企业。';

  @override
  String get businessReviewErrorApplicantInactive => '申请人的账户未处于活跃状态，无法批准此企业。';

  @override
  String get noticeBusinessReviewNew => '有新的企业注册待审核';

  @override
  String get noticeBusinessReviewSecond => '企业注册等待第二位审核员';

  @override
  String get noticeBusinessReviewRestart => '审核员对企业注册意见不一致，请重新审核';

  @override
  String get noticeBusinessApproved => '您的企业已通过验证';

  @override
  String get noticeBusinessRejected => '企业注册未获批准，请查看原因。';

  @override
  String get businessRegStatusReasonLabel => '审核员备注';

  @override
  String get dashAccountInfoTitle => '账户信息';

  @override
  String get dashDetails => '详情';

  @override
  String get dashDisplayNameLabel => '显示名称';

  @override
  String dashKaoIdLine(String kaoId) {
    return 'Kao ID：$kaoId';
  }

  @override
  String get dashKaoIdPending => '完成全部验证后将发放 Kao ID';

  @override
  String get dashFinanceTitle => '资金';

  @override
  String get dashServicesTitle => '使用 Kao ID 的服务';

  @override
  String get dashSecondhandName => 'KaoSure Secondhand';

  @override
  String get dashBusinessName => '企业';

  @override
  String get dashServiceAvailable => '可使用';

  @override
  String get dashServiceOpen => '打开';

  @override
  String get dashBusinessRegister => '注册';

  @override
  String get dashNotRegistered => '未注册';

  @override
  String get dashDraft => '草稿';

  @override
  String get dashNotApproved => '未获批准';

  @override
  String get dashNotAdded => '未添加';

  @override
  String get dashLoadFailedShort => '无法加载';

  @override
  String get dashSecurityTitle => '登录与安全';

  @override
  String get dashSecurityDescription => '管理密码、两步验证和已登录的设备。';

  @override
  String get dashAdminCenter => '管理中心';
}
