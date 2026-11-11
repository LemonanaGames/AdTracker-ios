import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Influencer Simulator'**
  String get appTitle;

  /// No description provided for @tabHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get tabHome;

  /// No description provided for @tabCreate.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get tabCreate;

  /// No description provided for @tabSocial.
  ///
  /// In en, this message translates to:
  /// **'Social'**
  String get tabSocial;

  /// No description provided for @tabDeals.
  ///
  /// In en, this message translates to:
  /// **'Deals'**
  String get tabDeals;

  /// No description provided for @tabLife.
  ///
  /// In en, this message translates to:
  /// **'Life'**
  String get tabLife;

  /// No description provided for @gotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get gotIt;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @go.
  ///
  /// In en, this message translates to:
  /// **'Go'**
  String get go;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get seeAll;

  /// No description provided for @soon.
  ///
  /// In en, this message translates to:
  /// **'Soon'**
  String get soon;

  /// No description provided for @whatIsThis.
  ///
  /// In en, this message translates to:
  /// **'What is {term}?'**
  String whatIsThis(String term);

  /// No description provided for @badgeReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get badgeReady;

  /// No description provided for @badgeLocked.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get badgeLocked;

  /// No description provided for @badgeInProgress.
  ///
  /// In en, this message translates to:
  /// **'Growing'**
  String get badgeInProgress;

  /// No description provided for @badgeDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get badgeDone;

  /// No description provided for @cash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get cash;

  /// No description provided for @skillPoints.
  ///
  /// In en, this message translates to:
  /// **'Skill Points'**
  String get skillPoints;

  /// No description provided for @energy.
  ///
  /// In en, this message translates to:
  /// **'Energy'**
  String get energy;

  /// No description provided for @stress.
  ///
  /// In en, this message translates to:
  /// **'Stress'**
  String get stress;

  /// No description provided for @trust.
  ///
  /// In en, this message translates to:
  /// **'Trust'**
  String get trust;

  /// No description provided for @integrity.
  ///
  /// In en, this message translates to:
  /// **'Integrity'**
  String get integrity;

  /// No description provided for @followers.
  ///
  /// In en, this message translates to:
  /// **'Followers'**
  String get followers;

  /// No description provided for @views.
  ///
  /// In en, this message translates to:
  /// **'Views'**
  String get views;

  /// No description provided for @likes.
  ///
  /// In en, this message translates to:
  /// **'Likes'**
  String get likes;

  /// No description provided for @comments.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get comments;

  /// No description provided for @shares.
  ///
  /// In en, this message translates to:
  /// **'Shares'**
  String get shares;

  /// No description provided for @engagement.
  ///
  /// In en, this message translates to:
  /// **'Engagement'**
  String get engagement;

  /// No description provided for @newFollowers.
  ///
  /// In en, this message translates to:
  /// **'New followers'**
  String get newFollowers;

  /// No description provided for @quality.
  ///
  /// In en, this message translates to:
  /// **'Quality'**
  String get quality;

  /// No description provided for @posts.
  ///
  /// In en, this message translates to:
  /// **'Posts'**
  String get posts;

  /// No description provided for @levelShort.
  ///
  /// In en, this message translates to:
  /// **'Creator Level {level}'**
  String levelShort(int level);

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Become the Creator Everyone Knows'**
  String get welcomeTitle;

  /// No description provided for @welcomeBody.
  ///
  /// In en, this message translates to:
  /// **'Start with a cheap phone and zero followers. Post, grow on three networks, make choices that matter — and decide what kind of famous you become.'**
  String get welcomeBody;

  /// No description provided for @startMyStory.
  ///
  /// In en, this message translates to:
  /// **'Start My Story'**
  String get startMyStory;

  /// No description provided for @nameTitle.
  ///
  /// In en, this message translates to:
  /// **'What\'s your creator name?'**
  String get nameTitle;

  /// No description provided for @nameLabel.
  ///
  /// In en, this message translates to:
  /// **'Creator name'**
  String get nameLabel;

  /// No description provided for @handleLabel.
  ///
  /// In en, this message translates to:
  /// **'Handle'**
  String get handleLabel;

  /// No description provided for @shuffleHandle.
  ///
  /// In en, this message translates to:
  /// **'Suggest another handle'**
  String get shuffleHandle;

  /// No description provided for @nicheTitle.
  ///
  /// In en, this message translates to:
  /// **'What will you post about?'**
  String get nicheTitle;

  /// No description provided for @nicheBody.
  ///
  /// In en, this message translates to:
  /// **'All three are balanced. Pick the one that sounds most fun — you can post other topics too.'**
  String get nicheBody;

  /// No description provided for @avatarTitle.
  ///
  /// In en, this message translates to:
  /// **'Pick your look'**
  String get avatarTitle;

  /// No description provided for @avatarOption.
  ///
  /// In en, this message translates to:
  /// **'Look {number}'**
  String avatarOption(int number);

  /// No description provided for @personaTitle.
  ///
  /// In en, this message translates to:
  /// **'Creator style'**
  String get personaTitle;

  /// No description provided for @personaOnCamera.
  ///
  /// In en, this message translates to:
  /// **'On camera'**
  String get personaOnCamera;

  /// No description provided for @personaFaceless.
  ///
  /// In en, this message translates to:
  /// **'Faceless'**
  String get personaFaceless;

  /// No description provided for @personaNote.
  ///
  /// In en, this message translates to:
  /// **'Style is cosmetic for now. Both play the same.'**
  String get personaNote;

  /// No description provided for @looksGood.
  ///
  /// In en, this message translates to:
  /// **'Looks Good'**
  String get looksGood;

  /// No description provided for @saveLoadError.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t read your previous save. It was kept safely on this device; you can start a new story.'**
  String get saveLoadError;

  /// No description provided for @createPost.
  ///
  /// In en, this message translates to:
  /// **'Create Post'**
  String get createPost;

  /// No description provided for @latestPost.
  ///
  /// In en, this message translates to:
  /// **'Latest post'**
  String get latestPost;

  /// No description provided for @newStory.
  ///
  /// In en, this message translates to:
  /// **'New story'**
  String get newStory;

  /// No description provided for @mayaName.
  ///
  /// In en, this message translates to:
  /// **'Maya'**
  String get mayaName;

  /// No description provided for @introMaya.
  ///
  /// In en, this message translates to:
  /// **'Every famous creator started with a first post. Let\'s make yours.'**
  String get introMaya;

  /// No description provided for @awayTitle.
  ///
  /// In en, this message translates to:
  /// **'While you were away'**
  String get awayTitle;

  /// No description provided for @awayViews.
  ///
  /// In en, this message translates to:
  /// **'+{count} views'**
  String awayViews(String count);

  /// No description provided for @awayFollowers.
  ///
  /// In en, this message translates to:
  /// **'+{count} followers'**
  String awayFollowers(String count);

  /// No description provided for @awayIncome.
  ///
  /// In en, this message translates to:
  /// **'{amount} in earnings ready to collect'**
  String awayIncome(String amount);

  /// No description provided for @awayCapped.
  ///
  /// In en, this message translates to:
  /// **'Progress counts for up to {hours} hours away.'**
  String awayCapped(int hours);

  /// No description provided for @earningsReady.
  ///
  /// In en, this message translates to:
  /// **'Earnings ready'**
  String get earningsReady;

  /// No description provided for @collect.
  ///
  /// In en, this message translates to:
  /// **'Collect'**
  String get collect;

  /// No description provided for @collected.
  ///
  /// In en, this message translates to:
  /// **'Collected {amount}!'**
  String collected(String amount);

  /// No description provided for @totalFollowersAcross.
  ///
  /// In en, this message translates to:
  /// **'Total followers across networks'**
  String get totalFollowersAcross;

  /// No description provided for @totalFollowersInfo.
  ///
  /// In en, this message translates to:
  /// **'This adds up your followers on Loop, TubeCast and Vibe. Some people follow you in more than one place, so it is not the number of different people. \"Estimated unique reach\" is our modeled guess of different people.'**
  String get totalFollowersInfo;

  /// No description provided for @uniqueReach.
  ///
  /// In en, this message translates to:
  /// **'Estimated unique reach ≈ {count} (modeled)'**
  String uniqueReach(String count);

  /// No description provided for @nextGoal.
  ///
  /// In en, this message translates to:
  /// **'Next goal'**
  String get nextGoal;

  /// No description provided for @allGoalsDone.
  ///
  /// In en, this message translates to:
  /// **'You finished every goal in this version. More chapters are coming!'**
  String get allGoalsDone;

  /// No description provided for @engagementShort.
  ///
  /// In en, this message translates to:
  /// **'{percent} engagement'**
  String engagementShort(String percent);

  /// No description provided for @chartLabel.
  ///
  /// In en, this message translates to:
  /// **'Views over time for this post'**
  String get chartLabel;

  /// No description provided for @stepNetwork.
  ///
  /// In en, this message translates to:
  /// **'1 · Network'**
  String get stepNetwork;

  /// No description provided for @stepTopic.
  ///
  /// In en, this message translates to:
  /// **'2 · Topic'**
  String get stepTopic;

  /// No description provided for @stepHook.
  ///
  /// In en, this message translates to:
  /// **'3 · Hook'**
  String get stepHook;

  /// No description provided for @stepGear.
  ///
  /// In en, this message translates to:
  /// **'4 · Gear'**
  String get stepGear;

  /// No description provided for @stepPreview.
  ///
  /// In en, this message translates to:
  /// **'5 · Preview'**
  String get stepPreview;

  /// No description provided for @upgradeGear.
  ///
  /// In en, this message translates to:
  /// **'Upgrade'**
  String get upgradeGear;

  /// No description provided for @startHere.
  ///
  /// In en, this message translates to:
  /// **'Start here'**
  String get startHere;

  /// No description provided for @yourNiche.
  ///
  /// In en, this message translates to:
  /// **'Your niche'**
  String get yourNiche;

  /// No description provided for @offNiche.
  ///
  /// In en, this message translates to:
  /// **'Other niche'**
  String get offNiche;

  /// No description provided for @trending.
  ///
  /// In en, this message translates to:
  /// **'Trending today'**
  String get trending;

  /// No description provided for @qNicheFit.
  ///
  /// In en, this message translates to:
  /// **'Topic fit'**
  String get qNicheFit;

  /// No description provided for @qGear.
  ///
  /// In en, this message translates to:
  /// **'Gear'**
  String get qGear;

  /// No description provided for @qHook.
  ///
  /// In en, this message translates to:
  /// **'Hook'**
  String get qHook;

  /// No description provided for @qSkills.
  ///
  /// In en, this message translates to:
  /// **'Skills'**
  String get qSkills;

  /// No description provided for @qStory.
  ///
  /// In en, this message translates to:
  /// **'Story bonus'**
  String get qStory;

  /// No description provided for @qStress.
  ///
  /// In en, this message translates to:
  /// **'Stress'**
  String get qStress;

  /// No description provided for @expectedViews.
  ///
  /// In en, this message translates to:
  /// **'Expected views: {min}–{max}'**
  String expectedViews(String min, String max);

  /// No description provided for @viralChance.
  ///
  /// In en, this message translates to:
  /// **'{percent}% chance to go viral (more views)'**
  String viralChance(int percent);

  /// No description provided for @energyCost.
  ///
  /// In en, this message translates to:
  /// **'Uses {cost} energy (you have {current})'**
  String energyCost(int cost, int current);

  /// No description provided for @xpGain.
  ///
  /// In en, this message translates to:
  /// **'+{xp} XP'**
  String xpGain(int xp);

  /// No description provided for @forecastNote.
  ///
  /// In en, this message translates to:
  /// **'Estimates, not promises: trends and luck change real results.'**
  String get forecastNote;

  /// No description provided for @notEnoughEnergy.
  ///
  /// In en, this message translates to:
  /// **'Not enough energy. Energy refills by itself — ready in about {seconds}s, or work later.'**
  String notEnoughEnergy(int seconds);

  /// No description provided for @publish.
  ///
  /// In en, this message translates to:
  /// **'Publish'**
  String get publish;

  /// No description provided for @publishing.
  ///
  /// In en, this message translates to:
  /// **'Publishing…'**
  String get publishing;

  /// No description provided for @published.
  ///
  /// In en, this message translates to:
  /// **'Published!'**
  String get published;

  /// No description provided for @goingViral.
  ///
  /// In en, this message translates to:
  /// **'It is going viral!'**
  String get goingViral;

  /// No description provided for @qualityAndXp.
  ///
  /// In en, this message translates to:
  /// **'Quality {quality}/100 · +{xp} XP'**
  String qualityAndXp(int quality, int xp);

  /// No description provided for @keepsGrowing.
  ///
  /// In en, this message translates to:
  /// **'Your post keeps getting views for a while — check back soon.'**
  String get keepsGrowing;

  /// No description provided for @tipFollowers.
  ///
  /// In en, this message translates to:
  /// **'Followers are people who want to see your next post.'**
  String get tipFollowers;

  /// No description provided for @backHome.
  ///
  /// In en, this message translates to:
  /// **'Back home'**
  String get backHome;

  /// No description provided for @makeAnother.
  ///
  /// In en, this message translates to:
  /// **'Make another post'**
  String get makeAnother;

  /// No description provided for @unlockHow.
  ///
  /// In en, this message translates to:
  /// **'How to unlock'**
  String get unlockHow;

  /// No description provided for @views7d.
  ///
  /// In en, this message translates to:
  /// **'Views (7 days)'**
  String get views7d;

  /// No description provided for @earnedHere.
  ///
  /// In en, this message translates to:
  /// **'Earned'**
  String get earnedHere;

  /// No description provided for @followersInfo.
  ///
  /// In en, this message translates to:
  /// **'Followers are people who want to see your next post on this network. Each network has its own followers.'**
  String get followersInfo;

  /// No description provided for @views7dInfo.
  ///
  /// In en, this message translates to:
  /// **'Views from posts you published in the last 7 game days on this network.'**
  String get views7dInfo;

  /// No description provided for @engagementInfo.
  ///
  /// In en, this message translates to:
  /// **'Engagement = how many people react to your posts. We count likes + comments + shares, divided by views, for posts from the last 7 game days.'**
  String get engagementInfo;

  /// No description provided for @earnedInfo.
  ///
  /// In en, this message translates to:
  /// **'Game cash this network has paid you so far. Collect it on Home.'**
  String get earnedInfo;

  /// No description provided for @noPostsYet.
  ///
  /// In en, this message translates to:
  /// **'No posts here yet.'**
  String get noPostsYet;

  /// No description provided for @postLine.
  ///
  /// In en, this message translates to:
  /// **'{views} views · {likes} likes · +{followers} followers'**
  String postLine(String views, String likes, String followers);

  /// No description provided for @postMissing.
  ///
  /// In en, this message translates to:
  /// **'This post is no longer available.'**
  String get postMissing;

  /// No description provided for @chartCaption.
  ///
  /// In en, this message translates to:
  /// **'Bright line: views so far. Faded line: where views are heading.'**
  String get chartCaption;

  /// No description provided for @whyQuality.
  ///
  /// In en, this message translates to:
  /// **'Why quality was {quality}'**
  String whyQuality(int quality);

  /// No description provided for @luckNormal.
  ///
  /// In en, this message translates to:
  /// **'Luck: a normal day for this post.'**
  String get luckNormal;

  /// No description provided for @luckViral.
  ///
  /// In en, this message translates to:
  /// **'Luck: this post got a viral boost!'**
  String get luckViral;

  /// No description provided for @dealsComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Brand deals open in the next update. Here is what brands will look for, using your real stats.'**
  String get dealsComingSoon;

  /// No description provided for @dealsWhatBrandsCheck.
  ///
  /// In en, this message translates to:
  /// **'What brands check'**
  String get dealsWhatBrandsCheck;

  /// No description provided for @dealsLaterTiers.
  ///
  /// In en, this message translates to:
  /// **'Bigger deals later'**
  String get dealsLaterTiers;

  /// No description provided for @tierTitle.
  ///
  /// In en, this message translates to:
  /// **'{tier} deals on {network}'**
  String tierTitle(String tier, String network);

  /// No description provided for @tierReward.
  ///
  /// In en, this message translates to:
  /// **'Pays {min}–{max} in game cash'**
  String tierReward(String min, String max);

  /// No description provided for @tierLine.
  ///
  /// In en, this message translates to:
  /// **'{followers} followers on {network}'**
  String tierLine(String followers, String network);

  /// No description provided for @followersOn.
  ///
  /// In en, this message translates to:
  /// **'{network} followers'**
  String followersOn(String network);

  /// No description provided for @views7dOn.
  ///
  /// In en, this message translates to:
  /// **'{network} views (7 days)'**
  String views7dOn(String network);

  /// No description provided for @engagementOn.
  ///
  /// In en, this message translates to:
  /// **'{network} engagement'**
  String engagementOn(String network);

  /// No description provided for @networkLockedNote.
  ///
  /// In en, this message translates to:
  /// **'{network} is still locked.'**
  String networkLockedNote(String network);

  /// No description provided for @wellbeing.
  ///
  /// In en, this message translates to:
  /// **'How you are doing'**
  String get wellbeing;

  /// No description provided for @jobs.
  ///
  /// In en, this message translates to:
  /// **'Jobs'**
  String get jobs;

  /// No description provided for @growth.
  ///
  /// In en, this message translates to:
  /// **'Grow'**
  String get growth;

  /// No description provided for @gearShop.
  ///
  /// In en, this message translates to:
  /// **'Gear'**
  String get gearShop;

  /// No description provided for @skills.
  ///
  /// In en, this message translates to:
  /// **'Skills'**
  String get skills;

  /// No description provided for @energyInfo.
  ///
  /// In en, this message translates to:
  /// **'You need energy to post and work. It refills by itself ({perHour} per game hour) — even while the app is closed.'**
  String energyInfo(int perHour);

  /// No description provided for @stressInfo.
  ///
  /// In en, this message translates to:
  /// **'Stress grows when you post or work a lot. High stress lowers post quality. It goes down by itself over time.'**
  String get stressInfo;

  /// No description provided for @trustInfo.
  ///
  /// In en, this message translates to:
  /// **'How much your audience believes you. Higher trust turns more viewers into followers.'**
  String get trustInfo;

  /// No description provided for @integrityInfo.
  ///
  /// In en, this message translates to:
  /// **'How true you stay to yourself. Some story choices change it, and later chapters care about it.'**
  String get integrityInfo;

  /// No description provided for @jobLine.
  ///
  /// In en, this message translates to:
  /// **'Earn {pay} · uses {energy} energy'**
  String jobLine(String pay, int energy);

  /// No description provided for @work.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get work;

  /// No description provided for @tooTired.
  ///
  /// In en, this message translates to:
  /// **'Too tired — energy refills over time.'**
  String get tooTired;

  /// No description provided for @tooTiredShort.
  ///
  /// In en, this message translates to:
  /// **'Tired'**
  String get tooTiredShort;

  /// No description provided for @earned.
  ///
  /// In en, this message translates to:
  /// **'Earned {amount}'**
  String earned(String amount);

  /// No description provided for @ownedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} owned'**
  String ownedCount(int count);

  /// No description provided for @pointsToSpend.
  ///
  /// In en, this message translates to:
  /// **'{count} to spend'**
  String pointsToSpend(int count);

  /// No description provided for @homeSection.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeSection;

  /// No description provided for @homeSharedRoom.
  ///
  /// In en, this message translates to:
  /// **'Shared room'**
  String get homeSharedRoom;

  /// No description provided for @homesLater.
  ///
  /// In en, this message translates to:
  /// **'Moving out arrives in a later update.'**
  String get homesLater;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @aboutLine.
  ///
  /// In en, this message translates to:
  /// **'Content version {version}'**
  String aboutLine(String version);

  /// No description provided for @privacyLine.
  ///
  /// In en, this message translates to:
  /// **'This version keeps everything on this device. Nothing is uploaded and no ads or purchases are active.'**
  String get privacyLine;

  /// No description provided for @xpProgress.
  ///
  /// In en, this message translates to:
  /// **'{current} / {total} XP'**
  String xpProgress(int current, int total);

  /// No description provided for @gearIntro.
  ///
  /// In en, this message translates to:
  /// **'Better gear makes better posts. Your gear adds +{quality} quality right now.'**
  String gearIntro(int quality);

  /// No description provided for @gearOwnedEffect.
  ///
  /// In en, this message translates to:
  /// **'Adds +{quality} quality'**
  String gearOwnedEffect(int quality);

  /// No description provided for @gearBeforeAfter.
  ///
  /// In en, this message translates to:
  /// **'Gear quality +{before} → +{after}'**
  String gearBeforeAfter(int before, int after);

  /// No description provided for @needMore.
  ///
  /// In en, this message translates to:
  /// **'Need {amount} more'**
  String needMore(String amount);

  /// No description provided for @bought.
  ///
  /// In en, this message translates to:
  /// **'{item} is yours!'**
  String bought(String item);

  /// No description provided for @moreGearLater.
  ///
  /// In en, this message translates to:
  /// **'More gear (editing apps, laptops, studios) unlocks in later updates.'**
  String get moreGearLater;

  /// No description provided for @skillPointsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} Skill Points'**
  String skillPointsCount(int count);

  /// No description provided for @skillPointsHow.
  ///
  /// In en, this message translates to:
  /// **'You get 1 Skill Point each time you reach a new Creator Level.'**
  String get skillPointsHow;

  /// No description provided for @rankOf.
  ///
  /// In en, this message translates to:
  /// **'Rank {rank} / {max}'**
  String rankOf(int rank, int max);

  /// No description provided for @plusOne.
  ///
  /// In en, this message translates to:
  /// **'+1'**
  String get plusOne;

  /// No description provided for @skillQuality.
  ///
  /// In en, this message translates to:
  /// **'+{value} quality'**
  String skillQuality(String value);

  /// No description provided for @skillLongViews.
  ///
  /// In en, this message translates to:
  /// **'+{value}% long-video views'**
  String skillLongViews(String value);

  /// No description provided for @skillReach.
  ///
  /// In en, this message translates to:
  /// **'+{value}% reach'**
  String skillReach(String value);

  /// No description provided for @skillNotYet.
  ///
  /// In en, this message translates to:
  /// **'Works once brand deals open'**
  String get skillNotYet;

  /// No description provided for @beforeAfter.
  ///
  /// In en, this message translates to:
  /// **'{before} → {after}'**
  String beforeAfter(String before, String after);

  /// No description provided for @whatDoYouDo.
  ///
  /// In en, this message translates to:
  /// **'What do you do?'**
  String get whatDoYouDo;

  /// No description provided for @decideLater.
  ///
  /// In en, this message translates to:
  /// **'Decide later'**
  String get decideLater;

  /// No description provided for @fxTrust.
  ///
  /// In en, this message translates to:
  /// **'Trust {delta}'**
  String fxTrust(String delta);

  /// No description provided for @fxIntegrity.
  ///
  /// In en, this message translates to:
  /// **'Integrity {delta}'**
  String fxIntegrity(String delta);

  /// No description provided for @fxCash.
  ///
  /// In en, this message translates to:
  /// **'Cash {amount}'**
  String fxCash(String amount);

  /// No description provided for @fxXp.
  ///
  /// In en, this message translates to:
  /// **'+{xp} XP'**
  String fxXp(int xp);

  /// No description provided for @fxRelationship.
  ///
  /// In en, this message translates to:
  /// **'{name} {delta}'**
  String fxRelationship(String name, String delta);

  /// No description provided for @fxTrendBoost.
  ///
  /// In en, this message translates to:
  /// **'Next {network} post: +{percent}% trend ({uses}×)'**
  String fxTrendBoost(int percent, String network, int uses);

  /// No description provided for @fxQualityBonus.
  ///
  /// In en, this message translates to:
  /// **'Next {uses} posts: +{bonus} quality'**
  String fxQualityBonus(int bonus, int uses);

  /// No description provided for @celebrateLevelUp.
  ///
  /// In en, this message translates to:
  /// **'Level up! Creator Level {level} · +1 Skill Point'**
  String celebrateLevelUp(int level);

  /// No description provided for @celebrateUnlocked.
  ///
  /// In en, this message translates to:
  /// **'{network} unlocked! Try it in Create.'**
  String celebrateUnlocked(String network);

  /// No description provided for @celebrateMilestone.
  ///
  /// In en, this message translates to:
  /// **'{count} followers on {network}!'**
  String celebrateMilestone(String count, String network);

  /// No description provided for @celebrateAct.
  ///
  /// In en, this message translates to:
  /// **'New chapter: {act}'**
  String celebrateAct(String act);

  /// No description provided for @reqAlways.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get reqAlways;

  /// No description provided for @reqAnyOf.
  ///
  /// In en, this message translates to:
  /// **'Any one of these:'**
  String get reqAnyOf;

  /// No description provided for @reqAllOf.
  ///
  /// In en, this message translates to:
  /// **'All of these:'**
  String get reqAllOf;

  /// No description provided for @reqFollowers.
  ///
  /// In en, this message translates to:
  /// **'{current} / {target} {network} followers'**
  String reqFollowers(String current, String target, String network);

  /// No description provided for @reqEngagement.
  ///
  /// In en, this message translates to:
  /// **'{network} engagement {current} / {target}'**
  String reqEngagement(String network, String current, String target);

  /// No description provided for @reqTotalFollowers.
  ///
  /// In en, this message translates to:
  /// **'{current} / {target} total followers'**
  String reqTotalFollowers(String current, String target);

  /// No description provided for @reqLevel.
  ///
  /// In en, this message translates to:
  /// **'Creator Level {current} / {target}'**
  String reqLevel(int current, int target);

  /// No description provided for @reqAct.
  ///
  /// In en, this message translates to:
  /// **'Reach {act}'**
  String reqAct(String act);

  /// No description provided for @reqGear.
  ///
  /// In en, this message translates to:
  /// **'Own {item}'**
  String reqGear(String item);

  /// No description provided for @reqFlag.
  ///
  /// In en, this message translates to:
  /// **'Unlocked by a story choice'**
  String get reqFlag;

  /// No description provided for @reqTrust.
  ///
  /// In en, this message translates to:
  /// **'Trust {current} / {target}'**
  String reqTrust(int current, int target);

  /// No description provided for @reqCash.
  ///
  /// In en, this message translates to:
  /// **'Cash {current} / {target}'**
  String reqCash(String current, String target);

  /// No description provided for @reqPostViews.
  ///
  /// In en, this message translates to:
  /// **'A post with {target} views (best so far: {current})'**
  String reqPostViews(String target, String current);

  /// No description provided for @reqPosts.
  ///
  /// In en, this message translates to:
  /// **'Posts published {current} / {target}'**
  String reqPosts(int current, int target);

  /// No description provided for @reqShifts.
  ///
  /// In en, this message translates to:
  /// **'Job shifts {current} / {target}'**
  String reqShifts(int current, int target);

  /// No description provided for @reqCollect.
  ///
  /// In en, this message translates to:
  /// **'Collect your earnings once on Home'**
  String get reqCollect;

  /// No description provided for @reqNetworkPosts.
  ///
  /// In en, this message translates to:
  /// **'{network} posts {current} / {target}'**
  String reqNetworkPosts(String network, int current, int target);

  /// No description provided for @reqGeneric.
  ///
  /// In en, this message translates to:
  /// **'{current} / {target}'**
  String reqGeneric(int current, int target);
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
