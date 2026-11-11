// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Influencer Simulator';

  @override
  String get tabHome => 'Home';

  @override
  String get tabCreate => 'Create';

  @override
  String get tabSocial => 'Social';

  @override
  String get tabDeals => 'Deals';

  @override
  String get tabLife => 'Life';

  @override
  String get gotIt => 'Got it';

  @override
  String get back => 'Back';

  @override
  String get continueLabel => 'Continue';

  @override
  String get go => 'Go';

  @override
  String get seeAll => 'See all';

  @override
  String get soon => 'Soon';

  @override
  String whatIsThis(String term) {
    return 'What is $term?';
  }

  @override
  String get badgeReady => 'Ready';

  @override
  String get badgeLocked => 'Locked';

  @override
  String get badgeInProgress => 'Growing';

  @override
  String get badgeDone => 'Done';

  @override
  String get cash => 'Cash';

  @override
  String get skillPoints => 'Skill Points';

  @override
  String get energy => 'Energy';

  @override
  String get stress => 'Stress';

  @override
  String get trust => 'Trust';

  @override
  String get integrity => 'Integrity';

  @override
  String get followers => 'Followers';

  @override
  String get views => 'Views';

  @override
  String get likes => 'Likes';

  @override
  String get comments => 'Comments';

  @override
  String get shares => 'Shares';

  @override
  String get engagement => 'Engagement';

  @override
  String get newFollowers => 'New followers';

  @override
  String get quality => 'Quality';

  @override
  String get posts => 'Posts';

  @override
  String levelShort(int level) {
    return 'Creator Level $level';
  }

  @override
  String get welcomeTitle => 'Become the Creator Everyone Knows';

  @override
  String get welcomeBody =>
      'Start with a cheap phone and zero followers. Post, grow on three networks, make choices that matter — and decide what kind of famous you become.';

  @override
  String get startMyStory => 'Start My Story';

  @override
  String get nameTitle => 'What\'s your creator name?';

  @override
  String get nameLabel => 'Creator name';

  @override
  String get handleLabel => 'Handle';

  @override
  String get shuffleHandle => 'Suggest another handle';

  @override
  String get nicheTitle => 'What will you post about?';

  @override
  String get nicheBody => 'All three are balanced. Pick the one that sounds most fun — you can post other topics too.';

  @override
  String get avatarTitle => 'Pick your look';

  @override
  String avatarOption(int number) {
    return 'Look $number';
  }

  @override
  String get personaTitle => 'Creator style';

  @override
  String get personaOnCamera => 'On camera';

  @override
  String get personaFaceless => 'Faceless';

  @override
  String get personaNote => 'Style is cosmetic for now. Both play the same.';

  @override
  String get looksGood => 'Looks Good';

  @override
  String get saveLoadError =>
      'We couldn\'t read your previous save. It was kept safely on this device; you can start a new story.';

  @override
  String get createPost => 'Create Post';

  @override
  String get latestPost => 'Latest post';

  @override
  String get newStory => 'New story';

  @override
  String get mayaName => 'Maya';

  @override
  String get introMaya => 'Every famous creator started with a first post. Let\'s make yours.';

  @override
  String get awayTitle => 'While you were away';

  @override
  String awayViews(String count) {
    return '+$count views';
  }

  @override
  String awayFollowers(String count) {
    return '+$count followers';
  }

  @override
  String awayIncome(String amount) {
    return '$amount in earnings ready to collect';
  }

  @override
  String awayCapped(int hours) {
    return 'Progress counts for up to $hours hours away.';
  }

  @override
  String get earningsReady => 'Earnings ready';

  @override
  String get collect => 'Collect';

  @override
  String get totalFollowersAcross => 'Total followers across networks';

  @override
  String get totalFollowersInfo =>
      'This adds up your followers on Loop, TubeCast and Vibe. Some people follow you in more than one place, so it is not the number of different people. \"Estimated unique reach\" is our modeled guess of different people.';

  @override
  String uniqueReach(String count) {
    return 'Estimated unique reach ≈ $count (modeled)';
  }

  @override
  String get nextGoal => 'Next goal';

  @override
  String get allGoalsDone => 'You finished every goal in this version. More chapters are coming!';

  @override
  String engagementShort(String percent) {
    return '$percent engagement';
  }

  @override
  String get chartLabel => 'Views over time for this post';

  @override
  String get stepNetwork => '1 · Network';

  @override
  String get stepTopic => '2 · Topic';

  @override
  String get stepHook => '3 · Hook';

  @override
  String get stepGear => '4 · Gear';

  @override
  String get stepPreview => '5 · Preview';

  @override
  String get upgradeGear => 'Upgrade';

  @override
  String get startHere => 'Start here';

  @override
  String get yourNiche => 'Your niche';

  @override
  String get offNiche => 'Other niche';

  @override
  String get trending => 'Trending today';

  @override
  String get qNicheFit => 'Topic fit';

  @override
  String get qGear => 'Gear';

  @override
  String get qHook => 'Hook';

  @override
  String get qSkills => 'Skills';

  @override
  String get qStory => 'Story bonus';

  @override
  String get qStress => 'Stress';

  @override
  String expectedViews(String min, String max) {
    return 'Expected views: $min–$max';
  }

  @override
  String viralChance(int percent) {
    return '$percent% chance to go viral (more views)';
  }

  @override
  String energyCost(int cost, int current) {
    return 'Uses $cost energy (you have $current)';
  }

  @override
  String xpGain(int xp) {
    return '+$xp XP';
  }

  @override
  String get forecastNote => 'Estimates, not promises: trends and luck change real results.';

  @override
  String notEnoughEnergy(int seconds) {
    return 'Not enough energy. Energy refills by itself — ready in about ${seconds}s, or work later.';
  }

  @override
  String get publish => 'Publish';

  @override
  String get publishing => 'Publishing…';

  @override
  String get published => 'Published!';

  @override
  String get goingViral => 'It is going viral!';

  @override
  String qualityAndXp(int quality, int xp) {
    return 'Quality $quality/100 · +$xp XP';
  }

  @override
  String get keepsGrowing => 'Your post keeps getting views for a while — check back soon.';

  @override
  String get tipFollowers => 'Followers are people who want to see your next post.';

  @override
  String get backHome => 'Back home';

  @override
  String get makeAnother => 'Make another post';

  @override
  String get unlockHow => 'How to unlock';

  @override
  String get views7d => 'Views (7 days)';

  @override
  String get earnedHere => 'Earned';

  @override
  String get followersInfo =>
      'Followers are people who want to see your next post on this network. Each network has its own followers.';

  @override
  String get views7dInfo => 'Views from posts you published in the last 7 game days on this network.';

  @override
  String get engagementInfo =>
      'Engagement = how many people react to your posts. We count likes + comments + shares, divided by views, for posts from the last 7 game days.';

  @override
  String get earnedInfo => 'Game cash this network has paid you so far. Collect it on Home.';

  @override
  String get noPostsYet => 'No posts here yet.';

  @override
  String postLine(String views, String likes, String followers) {
    return '$views views · $likes likes · +$followers followers';
  }

  @override
  String get postMissing => 'This post is no longer available.';

  @override
  String get chartCaption => 'Bright line: views so far. Faded line: where views are heading.';

  @override
  String whyQuality(int quality) {
    return 'Why quality was $quality';
  }

  @override
  String get luckNormal => 'Luck: a normal day for this post.';

  @override
  String get luckViral => 'Luck: this post got a viral boost!';

  @override
  String get dealsComingSoon =>
      'Brand deals open in the next update. Here is what brands will look for, using your real stats.';

  @override
  String get dealsWhatBrandsCheck => 'What brands check';

  @override
  String get dealsLaterTiers => 'Bigger deals later';

  @override
  String tierTitle(String tier, String network) {
    return '$tier deals on $network';
  }

  @override
  String tierReward(String min, String max) {
    return 'Pays $min–$max in game cash';
  }

  @override
  String tierLine(String followers, String network) {
    return '$followers followers on $network';
  }

  @override
  String followersOn(String network) {
    return '$network followers';
  }

  @override
  String views7dOn(String network) {
    return '$network views (7 days)';
  }

  @override
  String engagementOn(String network) {
    return '$network engagement';
  }

  @override
  String networkLockedNote(String network) {
    return '$network is still locked.';
  }

  @override
  String get wellbeing => 'How you are doing';

  @override
  String get jobs => 'Jobs';

  @override
  String get growth => 'Grow';

  @override
  String get gearShop => 'Gear';

  @override
  String get skills => 'Skills';

  @override
  String energyInfo(int perHour) {
    return 'You need energy to post and work. It refills by itself ($perHour per game hour) — even while the app is closed.';
  }

  @override
  String get stressInfo =>
      'Stress grows when you post or work a lot. High stress lowers post quality. It goes down by itself over time.';

  @override
  String get trustInfo => 'How much your audience believes you. Higher trust turns more viewers into followers.';

  @override
  String get integrityInfo =>
      'How true you stay to yourself. Some story choices change it, and later chapters care about it.';

  @override
  String jobLine(String pay, int energy) {
    return 'Earn $pay · uses $energy energy';
  }

  @override
  String get work => 'Work';

  @override
  String get tooTired => 'Too tired — energy refills over time.';

  @override
  String get tooTiredShort => 'Tired';

  @override
  String earned(String amount) {
    return 'Earned $amount';
  }

  @override
  String ownedCount(int count) {
    return '$count owned';
  }

  @override
  String pointsToSpend(int count) {
    return '$count to spend';
  }

  @override
  String get homeSection => 'Home';

  @override
  String get homeSharedRoom => 'Shared room';

  @override
  String get homesLater => 'Moving out arrives in a later update.';

  @override
  String get about => 'About';

  @override
  String aboutLine(String version) {
    return 'Content version $version';
  }

  @override
  String get privacyLine =>
      'This version keeps everything on this device. Nothing is uploaded and no ads or purchases are active.';

  @override
  String xpProgress(int current, int total) {
    return '$current / $total XP';
  }

  @override
  String gearIntro(int quality) {
    return 'Better gear makes better posts. Your gear adds +$quality quality right now.';
  }

  @override
  String gearOwnedEffect(int quality) {
    return 'Adds +$quality quality';
  }

  @override
  String gearBeforeAfter(int before, int after) {
    return 'Gear quality +$before → +$after';
  }

  @override
  String needMore(String amount) {
    return 'Need $amount more';
  }

  @override
  String bought(String item) {
    return '$item is yours!';
  }

  @override
  String get moreGearLater => 'More gear (editing apps, laptops, studios) unlocks in later updates.';

  @override
  String skillPointsCount(int count) {
    return '$count Skill Points';
  }

  @override
  String get skillPointsHow => 'You get 1 Skill Point each time you reach a new Creator Level.';

  @override
  String rankOf(int rank, int max) {
    return 'Rank $rank / $max';
  }

  @override
  String get plusOne => '+1';

  @override
  String skillQuality(String value) {
    return '+$value quality';
  }

  @override
  String skillLongViews(String value) {
    return '+$value% long-video views';
  }

  @override
  String skillReach(String value) {
    return '+$value% reach';
  }

  @override
  String get skillNotYet => 'Works once brand deals open';

  @override
  String beforeAfter(String before, String after) {
    return '$before → $after';
  }

  @override
  String get whatDoYouDo => 'What do you do?';

  @override
  String get decideLater => 'Decide later';

  @override
  String fxTrust(String delta) {
    return 'Trust $delta';
  }

  @override
  String fxIntegrity(String delta) {
    return 'Integrity $delta';
  }

  @override
  String fxCash(String amount) {
    return 'Cash $amount';
  }

  @override
  String fxXp(int xp) {
    return '+$xp XP';
  }

  @override
  String fxRelationship(String name, String delta) {
    return '$name $delta';
  }

  @override
  String fxTrendBoost(int percent, String network, int uses) {
    return 'Next $network post: +$percent% trend ($uses×)';
  }

  @override
  String fxQualityBonus(int bonus, int uses) {
    return 'Next $uses posts: +$bonus quality';
  }

  @override
  String celebrateMilestone(String count, String network) {
    return '$count followers on $network!';
  }

  @override
  String celebrateAct(String act) {
    return 'New chapter: $act';
  }

  @override
  String get reqAlways => 'Available';

  @override
  String get reqAnyOf => 'Any one of these:';

  @override
  String get reqAllOf => 'All of these:';

  @override
  String reqFollowers(String current, String target, String network) {
    return '$current / $target $network followers';
  }

  @override
  String reqEngagement(String network, String current, String target) {
    return '$network engagement $current / $target';
  }

  @override
  String reqTotalFollowers(String current, String target) {
    return '$current / $target total followers';
  }

  @override
  String reqLevel(int current, int target) {
    return 'Creator Level $current / $target';
  }

  @override
  String reqAct(String act) {
    return 'Reach $act';
  }

  @override
  String reqGear(String item) {
    return 'Own $item';
  }

  @override
  String get reqFlag => 'Unlocked by a story choice';

  @override
  String reqTrust(int current, int target) {
    return 'Trust $current / $target';
  }

  @override
  String reqCash(String current, String target) {
    return 'Cash $current / $target';
  }

  @override
  String reqPostViews(String target, String current) {
    return 'A post with $target views (best so far: $current)';
  }

  @override
  String reqPosts(int current, int target) {
    return 'Posts published $current / $target';
  }

  @override
  String reqShifts(int current, int target) {
    return 'Job shifts $current / $target';
  }

  @override
  String get reqCollect => 'Collect your earnings once on Home';

  @override
  String reqNetworkPosts(String network, int current, int target) {
    return '$network posts $current / $target';
  }

  @override
  String reqGeneric(int current, int target) {
    return '$current / $target';
  }

  @override
  String get live => 'Live';

  @override
  String get qualityOutOf => 'out of 100';

  @override
  String get settings => 'Settings';

  @override
  String get settingSound => 'Sound effects';

  @override
  String get settingHaptics => 'Vibration';

  @override
  String get settingNotifications => 'Reminders';

  @override
  String get settingNotificationsBody =>
      'When a post finishes or something is ready. At most 3 while you are away, never at night.';

  @override
  String get notifyAskTitle => 'Want a heads-up when this post finishes?';

  @override
  String get notifyAskBody => 'We\'ll tell you how it did. At most 3 reminders while you\'re away, never at night.';

  @override
  String get notifyYes => 'Notify me';

  @override
  String get notifyNo => 'Not now';

  @override
  String get notifyDenied => 'Notifications are off for this app. You can turn them on in your phone settings.';

  @override
  String celebrateLevelTitle(int level) {
    return 'Level $level!';
  }

  @override
  String get celebrateLevelBody => '+1 Skill Point. Spend it in Life → Skills to make better posts.';

  @override
  String celebrateUnlockTitle(String network) {
    return '$network unlocked!';
  }

  @override
  String get celebrateMilestoneBody => 'People are noticing you. Keep posting to grow even faster.';

  @override
  String get celebrateActBody => 'A new chapter of your story begins.';

  @override
  String get celebrateNice => 'Let\'s go!';

  @override
  String get celebrateNext => 'Next';

  @override
  String notifPostTitle(String topic) {
    return 'Your \"$topic\" post wrapped up';
  }

  @override
  String notifPostBody(String views, String followers, String network) {
    return '$views views and +$followers followers on $network. Come see how it did.';
  }

  @override
  String notifMilestoneTitle(String count, String network) {
    return '$count followers on $network!';
  }

  @override
  String get notifMilestoneBody => 'You just crossed a milestone. Your next goal is waiting.';

  @override
  String notifGearTitle(String item) {
    return 'You can afford the $item now';
  }

  @override
  String get notifGearBody => 'Your earnings cover it. Better gear means better posts.';

  @override
  String get notifEnergyTitle => 'Energy\'s full';

  @override
  String get notifEnergyBody => 'You\'re rested and ready to film something new.';

  @override
  String notifStoryTitle(String name) {
    return '$name sent you a message';
  }

  @override
  String get notifStoryBody => 'Something happened with your posts. Tap to read it.';

  @override
  String notifAwayTitle(String amount) {
    return '$amount is ready to collect';
  }

  @override
  String get notifAwayBody => 'Your posts kept earning while you were away.';

  @override
  String get notifDailyTitle => 'Ready for today\'s post?';

  @override
  String get notifDailyBody => 'New trends every game day. See what is hot right now.';

  @override
  String get zeroFollowers => '0 followers';
}
