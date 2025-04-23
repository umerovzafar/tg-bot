import 'package:teledart/model.dart';
import 'package:teledart/teledart.dart';

Future<void> sendPhotosWithTextInGroup(TeleDart teledart, int chatId) async {
  final photoUrls = [
    'https://i.imgur.com/lc3B7fy.jpeg',
    'https://i.imgur.com/TPpyBxs.jpeg',
    'https://i.imgur.com/5PqCoAf.jpeg',
    'https://i.imgur.com/ZdUGvje.jpeg',
  ];

  final introMessageRu = '''
Только 2 дня. Только в Ташкенте. Только для тех, кто хочет большего.
⠀
31 мая и 1 июня — уникальное событие, которого ждали все, кто стремится к росту!
⠀
Елена Орешкина, Genesis Education и Ринат Каримов — три сильнейших эксперта объединяют опыт, знания и энергию в одном мощном проекте!
⠀
Что тебя ждёт?
• Живой нетворкинг и окружение амбициозных людей
• Честные знания и практики, проверенные на опыте
• Сильная прокачка мышления и навыков
• Заряд мотивации на весь год
⠀
Будет мощно. Будет результат.
⠀
Стоимость участия: 1.300.000
''';

  final introMessageUz = '''
Faqat 2 kun. Faqat Toshkentda. Faqat kattaroq maqsadga intiluvchilar uchun.
⠀
31-may va 1-iyun — o‘sishni istaganlar uchun kutilgan noyob tadbir!
⠀
Elena Oreshkina, Genesis Education va Rinat Karimov — uch nafar kuchli ekspert tajriba, bilim va energiyalarini yagona kuchli loyihada birlashtirishmoqda!
⠀
Nima kutadi seni?
• Yuzma-yuz tanishuv va ambitsiyali insonlar muhiti
• Haqiqiy bilim va tajribada sinovdan o‘tgan amaliyotlar
• Kuchli fikrlash va ko‘nikmalarni rivojlantirish
• Yil davomiga yetadigan motivatsiya
⠀
Bu kuchli bo‘ladi. Bu natija beradi.
⠀
Ishtirok narxi: 1 300 000 so‘m
''';

  final mediaRu =
      photoUrls.map((url) {
        return InputMediaPhoto(media: url, caption: introMessageRu);
      }).toList();

  await teledart.sendMediaGroup(chatId, mediaRu);

  await teledart.sendMessage(chatId, introMessageRu);


  await teledart.sendMessage(chatId, introMessageUz);
}
