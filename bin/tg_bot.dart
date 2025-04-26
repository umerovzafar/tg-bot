import 'package:dotenv/dotenv.dart';
import 'package:teledart/teledart.dart';
import 'package:teledart/model.dart';
import 'package:teledart/telegram.dart';
import './translations.dart';
import './database.dart';
import './sending.dart';

final waitingForFullName = <int>{};
bool isPhotoProcessed = false;

Future<void> main() async {
  final env = DotEnv()..load();
  final String token = env['BOT_TOKEN']!;
  initDatabase();
  final username = (await Telegram(token).getMe()).username;
  final teledart = TeleDart(token, Event(username!));
  teledart.start();

  teledart.onCommand('start').listen((message) async {
    final chatId = message.chat.id;

    await sendPhotosWithTextInGroup(teledart, message.chat.id);

    await teledart.sendMessage(
      chatId,
      '${translations['choose_language']!['ru']}\n\n${translations['choose_language']!['uz']}',
      replyMarkup: ReplyKeyboardMarkup(
        keyboard: [
          [
            KeyboardButton(text: '🇷🇺 Русский'),
            KeyboardButton(text: '🇺🇿 O‘zbek tili'),
          ],
        ],
        resizeKeyboard: true,
        oneTimeKeyboard: true,
      ),
    );
  });

  teledart.onMessage().listen((message) {
    final chatId = message.chat.id;
    final text = message.text;

    if (text == '🇷🇺 Русский' || text == '🇺🇿 O‘zbek tili') {
      final String lang = text!.contains('Рус') ? 'ru' : 'uz';
      saveUser(chatId, '', lang);

      teledart.sendMessage(
        chatId,
        translations['send_phone']![lang]!,
        replyMarkup: ReplyKeyboardMarkup(
          keyboard: [
            [
              KeyboardButton(
                text: translations['send_contact_button']![lang]!,
                requestContact: true,
              ),
            ],
          ],
          resizeKeyboard: true,
          oneTimeKeyboard: true,
        ),
      );
      return;
    }

    if (message.contact != null) {
      final phone = message.contact!.phoneNumber;
      db.execute('UPDATE users SET phone = ? WHERE id = ?', [phone, chatId]);

      waitingForFullName.add(chatId);

      final lang = getUserLanguage(chatId) ?? 'ru';
      teledart.sendMessage(
        chatId,
        translations['send_name']![lang]!,
        replyMarkup: ReplyKeyboardMarkup(
          keyboard: [
            [KeyboardButton(text: translations['cancel']![lang]!)],
          ],
          resizeKeyboard: true,
          oneTimeKeyboard: true,
        ),
      );
      return;
    }

    if (text == translations['cancel']!['ru'] ||
        text == translations['cancel']!['uz']) {
      deleteUserData(chatId);

      teledart.sendMessage(
        chatId,
        '❌ Ваши данные были удалены. Пожалуйста, начните регистрацию заново.',
      );
      teledart.sendMessage(
        chatId,
        '${translations['choose_language']!['ru']}\n\n${translations['choose_language']!['uz']}',
        replyMarkup: ReplyKeyboardMarkup(
          keyboard: [
            [
              KeyboardButton(text: '🇷🇺 Русский'),
              KeyboardButton(text: '🇺🇿 O‘zbek tili'),
            ],
          ],
          resizeKeyboard: true,
          oneTimeKeyboard: true,
        ),
      );
      return;
    }

    if (waitingForFullName.contains(chatId) &&
        text != null &&
        text.isNotEmpty) {
      updateFullName(chatId, text);
      waitingForFullName.remove(chatId);

      final lang = getUserLanguage(chatId) ?? 'ru';
      teledart.sendMessage(
        chatId,
        translations['menu']![lang]!,
        replyMarkup: ReplyKeyboardMarkup(
          keyboard: [
            [
              KeyboardButton(text: translations['payment']![lang]!),
              KeyboardButton(text: translations['consultation']![lang]!),
            ],
            [KeyboardButton(text: translations['profile']![lang]!)],
          ],
          resizeKeyboard: true,
        ),
      );
    }

    if (text == translations['profile']!['ru'] ||
        text == translations['profile']!['uz']) {
      final profile = getUserProfile(chatId);
      if (profile != null) {
        final lang = getUserLanguage(chatId) ?? 'ru';
        final profileMessage = translations['profile_info']![lang]!
            .replaceFirst('{full_name}', '${profile['full_name']}\n')
            .replaceFirst('{phone}', '${profile['phone']}\n')
            .replaceFirst(
              '{language}',
              profile['language'] == 'ru' ? 'Русский' : 'O‘zbek tili',
            );

        teledart.sendMessage(chatId, profileMessage);
      } else {
        teledart.sendMessage(chatId, '❌ Ваш профиль не найден.');
      }
    }

    if (text == translations['consultation']!['ru'] ||
        text == translations['consultation']!['uz']) {
      final lang = getUserLanguage(chatId) ?? 'ru';
      teledart.sendMessage(chatId, translations['consultation_info']![lang]!);
    }

    if (text == translations['payment']!['ru'] ||
        text == translations['payment']!['uz']) {
      final lang = getUserLanguage(chatId) ?? 'ru';
      teledart.sendMessage(
        chatId,
        translations['payment_menu']![lang]!,
        replyMarkup: ReplyKeyboardMarkup(
          keyboard: [
            [
              KeyboardButton(text: translations['card_payment']![lang]!),
              KeyboardButton(text: translations['installment_payment']![lang]!),
            ],
            [KeyboardButton(text: translations['bank_transfer']![lang]!)],
            [KeyboardButton(text: translations['back']![lang]!)],
          ],
          resizeKeyboard: true,
        ),
      );
    }
    //
    if (text == translations['card_payment']!['ru'] ||
        text == translations['card_payment']!['uz']) {
      final lang = getUserLanguage(chatId) ?? 'ru';

      String message =
          lang == 'ru'
              ? '✅ Вы выбрали способ оплаты: Перевод на карту.\n\nСтоимость участия: 1.300.000\n\n📝 Пожалуйста, переведите сумму на следующий номер карты:\n\n💳 Номер карты: 5440 8103 0865 3178\n\n👤 Получатель: Орешкина Елена\n\nПосле перевода, пожалуйста, подтвердите!'
              : '✅ Siz toʻlov usulini tanladingiz: Kartaga oʻtkazish.\n\nIshtirok narxi: 1 300 000 so‘m\n\n📝 Iltimos, summa quyidagi karta raqamiga oʻtkazishing:\n\n💳 Karta raqami: 5440 8103 0865 3178\n\n👤 Oʻtkazuvchi: Oreshkina Elena\n\nPul oʻtkazmasini amalga oshirganingizdan soʻng, iltimos tasdiqlang!';

      teledart.sendMessage(chatId, message, parseMode: 'HTML');

      Future.delayed(Duration(seconds: 1), () {
        teledart.sendMessage(
          chatId,
          lang == 'ru'
              ? '⏳ Ожидаем подтверждение оплаты. Пожалуйста, отправьте фото с подтверждением перевода.'
              : '⏳ Toʻlov tasdiqlanganini kutyapmiz. Iltimos, oʻtkazish tasdiqlovchi fotosuratni yuboring.',
        );
      });
    }

    if (text == translations['bank_transfer']!['ru']! ||
        text == translations['bank_transfer']!['uz']!) {
      final lang = getUserLanguage(chatId) ?? 'ru';

      String message = translations['bank_transfer_info']![lang]!;

      teledart.sendMessage(chatId, message, parseMode: 'HTML');

      Future.delayed(Duration(seconds: 1), () {
        teledart.sendMessage(
          chatId,
          lang == 'ru'
              ? '⏳ Ожидаем подтверждение оплаты. Пожалуйста, отправьте фото с подтверждением перевода.'
              : '⏳ Toʻlov tasdiqlanganini kutyapmiz. Iltimos, oʻtkazmani tasdiqlovchi fotosuratni yuboring.',
        );
      });
    }

    if (text == translations['installment_payment']!['ru'] ||
        text == translations['installment_payment']!['uz']) {
      final lang = getUserLanguage(chatId) ?? 'ru';
      teledart.sendMessage(
        chatId,
        translations['installment_payment_info']![lang]!,
      );
    }

    if (text == translations['back']!['ru'] ||
        text == translations['back']!['uz']) {
      final lang = getUserLanguage(chatId) ?? 'ru';
      isPhotoProcessed = false;
      teledart.sendMessage(
        chatId,
        translations['menu']![lang]!,
        replyMarkup: ReplyKeyboardMarkup(
          keyboard: [
            [
              KeyboardButton(text: translations['payment']![lang]!),
              KeyboardButton(text: translations['consultation']![lang]!),
            ],
            [KeyboardButton(text: translations['profile']![lang]!)],
          ],
          resizeKeyboard: true,
        ),
      );
    }
  });

  teledart.onMessage().listen((message) async {
    if (message.photo != null && !isPhotoProcessed) {
      final photo = message.photo!.last;
      final profile = getUserProfile(message.chat.id);

      if (profile != null) {
        final fullName = profile['full_name'] ?? 'Не указано';
        final phoneNumber = profile['phone'] ?? 'Не указан';
        final lang = getUserLanguage(message.chat.id) ?? 'ru';

        await teledart.sendPhoto(
          message.chat.id,
          photo.fileId,
          caption:
              lang == 'ru'
                  ? '📸 Вот ваше фото подтверждения перевода.\n\n📛 ФИО: $fullName\n\n📱 Номер телефона: $phoneNumber'
                  : '📸 Bu sizning oʻtkazish tasdiqlovchi fotosuratingiz.\n\n📛 F.I.Sh: $fullName\n\n📱 Telefon raqami: $phoneNumber',
        );

        Future.delayed(Duration(seconds: 1), () async {
          isPhotoProcessed = false;
          await teledart.sendMessage(
            message.chat.id,
            lang == 'ru'
                ? '✅ Фото получено. Спасибо за подтверждение! Ожидайте дальнейшие инструкции.'
                : '✅ Surat olindi. Tasdiqlanganingiz uchun rahmat! Keyingi koʻrsatmalarga kuting.',
          );
        });

        String channelUsername = '@oplata_seminar';

        var inlineKeyboard = InlineKeyboardMarkup(
          inlineKeyboard: [
            [
              InlineKeyboardButton(
                text: lang == 'ru' ? 'Принять' : 'Qabul qilish',
                callbackData: 'accept_payment:${message.chat.id}',
              ),
              InlineKeyboardButton(
                text: lang == 'ru' ? 'Отклонить' : 'Rad etish',
                callbackData: 'reject_payment:${message.chat.id}',
              ),
            ],
          ],
        );

        Future.delayed(Duration(seconds: 1), () async {
          await teledart.sendPhoto(
            channelUsername,
            photo.fileId,
            caption:
                lang == 'ru'
                    ? '📝 Новый платеж подтвержден!\n\n📛 ФИО: $fullName\n📱 Номер телефона: $phoneNumber'
                    : '📝 Yangi toʻlov tasdiqlandi!\n\n📛 F.I.Sh: $fullName\n📱 Telefon raqami: $phoneNumber',
            replyMarkup: inlineKeyboard,
          );
        });

        isPhotoProcessed = false;
      }
    }
  });

  teledart.onCallbackQuery().listen((callbackQuery) async {
    final callbackData = callbackQuery.data;
    final messageId = callbackQuery.message!.messageId;
    final chatId = callbackQuery.message!.chat.id;
    final lang = getUserLanguage(chatId) ?? 'ru';
    final profile = getUserProfile(int.parse(callbackData!.split(':')[1]));

    if (callbackQuery.message!.text != null) {
      if (callbackData.split(':')[0] == 'accept_payment') {
        await teledart.editMessageText(
          chatId: callbackData.split(':')[0],
          messageId: messageId,
          lang == 'ru'
              ? '✅ Платеж принят.\n\nНомер телефона: ${profile!['phone']}\n\nФИО отправителя: ${profile['full_name']}'
              : '✅ Toʻlov qabul qilindi.\n\n📛 F.I.Sh: ${profile!['phone']}\n📱 Telefon raqami: ${profile['full_name']}',
        );
      } else if (callbackData.split(':')[0] == 'reject_payment') {
        await teledart.editMessageText(
          chatId: callbackData.split(':')[0],
          messageId: messageId,
          lang == 'ru'
              ? '❌ Платеж отклонен.\n\nНомер телефона: ${profile!['phone']}\n\nФИО отправителя: ${profile['full_name']}'
              : '❌ Toʻlov rad etildi.\n\n📛 F.I.Sh: ${profile!['phone']}\n📱 Telefon raqami: ${profile['full_name']}',
        );
      }
    } else if (callbackQuery.message!.photo != null) {
      if (callbackData.split(':')[0] == 'accept_payment') {
        await teledart.editMessageCaption(
          chatId: chatId,
          messageId: messageId,
          caption:
              lang == 'ru'
                  ? '✅ Платеж принят.\n\nНомер телефона: ${profile!['phone']}\n\nФИО отправителя: ${profile['full_name']}'
                  : '✅ Toʻlov qabul qilindi.\n\n📛 F.I.Sh: ${profile!['phone']}\n📱 Telefon raqami: ${profile['full_name']}',
        );
      } else if (callbackData.split(':')[0] == 'reject_payment') {
        await teledart.editMessageCaption(
          chatId: chatId,
          messageId: messageId,
          caption:
              lang == 'ru'
                  ? '❌ Платеж отклонен.\n\nНомер телефона: ${profile!['phone']}\n\nФИО отправителя: ${profile['full_name']}'
                  : '❌ Toʻlov rad etildi.\n\n📛 F.I.Sh: ${profile!['phone']}\n📱 Telefon raqami: ${profile['full_name']}',
        );
      }
    }
  });
}
