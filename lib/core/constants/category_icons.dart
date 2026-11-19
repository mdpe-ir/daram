import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// The single source of truth for category icons.
///
/// The keys are the `icon` slugs stored in the database, so renaming a key
/// would silently change every existing category. Add new slugs only.
const Map<String, IconData> categoryIconCatalog = <String, IconData>{
  // Food and drink
  'utensils': LucideIcons.utensils,
  'utensils-crossed': LucideIcons.utensilsCrossed,
  'cooking-pot': LucideIcons.cookingPot,
  'coffee': LucideIcons.coffee,
  'pizza': LucideIcons.pizza,
  'cake': LucideIcons.cake,
  'apple': LucideIcons.apple,
  'carrot': LucideIcons.carrot,
  'fish': LucideIcons.fish,
  'egg': LucideIcons.egg,
  'salad': LucideIcons.salad,
  'soup': LucideIcons.soup,
  'beef': LucideIcons.beef,
  'croissant': LucideIcons.croissant,
  'ice-cream-bowl': LucideIcons.iceCreamBowl,
  // Transport and travel
  'bus': LucideIcons.bus,
  'car': LucideIcons.car,
  'fuel': LucideIcons.fuel,
  'train-front': LucideIcons.trainFront,
  'bike': LucideIcons.bike,
  'plane': LucideIcons.plane,
  'tent': LucideIcons.tent,
  'mountain': LucideIcons.mountain,
  'hotel': LucideIcons.hotel,
  'luggage': LucideIcons.luggage,
  'ticket': LucideIcons.ticket,
  // Shopping and goods
  'shopping-bag': LucideIcons.shoppingBag,
  'shopping-cart': LucideIcons.shoppingCart,
  'shopping-basket': LucideIcons.shoppingBasket,
  'store': LucideIcons.store,
  'package': LucideIcons.package,
  'shirt': LucideIcons.shirt,
  'footprints': LucideIcons.footprints,
  'sparkles': LucideIcons.sparkles,
  // Home and bills
  'house': LucideIcons.house,
  'lightbulb': LucideIcons.lightbulb,
  'droplets': LucideIcons.droplets,
  'flame': LucideIcons.flame,
  'zap': LucideIcons.zap,
  'wifi': LucideIcons.wifi,
  'phone': LucideIcons.phone,
  'smartphone': LucideIcons.smartphone,
  'wrench': LucideIcons.wrench,
  'hammer': LucideIcons.hammer,
  'paint-roller': LucideIcons.paintRoller,
  'scissors': LucideIcons.scissors,
  'umbrella': LucideIcons.umbrella,
  'receipt-text': LucideIcons.receiptText,
  'file-text': LucideIcons.fileText,
  // Health and self-care
  'heart-pulse': LucideIcons.heartPulse,
  'heart': LucideIcons.heart,
  'pill': LucideIcons.pill,
  'stethoscope': LucideIcons.stethoscope,
  'syringe': LucideIcons.syringe,
  'dumbbell': LucideIcons.dumbbell,
  // Family and pets
  'baby': LucideIcons.baby,
  'users': LucideIcons.users,
  'user-round': LucideIcons.userRound,
  'handshake': LucideIcons.handshake,
  'dog': LucideIcons.dog,
  'cat': LucideIcons.cat,
  'paw-print': LucideIcons.pawPrint,
  // Learning and leisure
  'graduation-cap': LucideIcons.graduationCap,
  'book-open': LucideIcons.bookOpen,
  'pencil': LucideIcons.pencil,
  'music': LucideIcons.music,
  'film': LucideIcons.film,
  'tv': LucideIcons.tv,
  'camera': LucideIcons.camera,
  'palette': LucideIcons.palette,
  'gamepad-2': LucideIcons.gamepad2,
  'repeat-2': LucideIcons.repeat2,
  // Income, work and money
  'briefcase': LucideIcons.briefcase,
  'laptop': LucideIcons.laptop,
  'building-2': LucideIcons.building2,
  'hand-coins': LucideIcons.handCoins,
  'banknote': LucideIcons.banknote,
  'credit-card': LucideIcons.creditCard,
  'piggy-bank': LucideIcons.piggyBank,
  'coins': LucideIcons.coins,
  'wallet': LucideIcons.wallet,
  'landmark': LucideIcons.landmark,
  'circle-dollar-sign': LucideIcons.circleDollarSign,
  'percent': LucideIcons.percent,
  'calculator': LucideIcons.calculator,
  'chart-pie': LucideIcons.chartPie,
  'trending-up': LucideIcons.trendingUp,
  'trending-down': LucideIcons.trendingDown,
  'gem': LucideIcons.gem,
  'crown': LucideIcons.crown,
  'trophy': LucideIcons.trophy,
  'rocket': LucideIcons.rocket,
  'gift': LucideIcons.gift,
  'tag': LucideIcons.tag,
  'shield-check': LucideIcons.shieldCheck,
  // Fallbacks
  'circle-plus': LucideIcons.circlePlus,
  'circle-ellipsis': LucideIcons.circleEllipsis,
};

/// Slug used when a stored icon is unknown.
const String fallbackCategoryIcon = 'circle-ellipsis';

/// Every slug the editor offers, in catalog order.
List<String> get categoryIconSlugs => categoryIconCatalog.keys.toList();

/// Resolves a stored slug to its Lucide icon, falling back safely.
IconData categoryIcon(String slug) =>
    categoryIconCatalog[slug] ?? LucideIcons.circleEllipsis;
