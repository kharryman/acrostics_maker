import 'dart:io';
import 'dart:math';

import 'package:acrostics_maker/globals.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdService {
  static int showInterstitialPerThousand = 300; // 300 / 1000
  static VoidCallback? _pendingInterstitialComplete;

  static final Random _random = Random();

  static bool _isBannerReady = false;

  static InterstitialAd? _interstitialAd;

  static RewardedAd? _rewardedAd;

  static int _interstitialLoadAttempts = 0;
  static const int _maxFailedLoadAttempts = 5;

  // ─────────────────────────────────────────────────────────────
  // AD REQUEST
  // ─────────────────────────────────────────────────────────────

  static final AdRequest request = AdRequest(
    keywords: <String>[
      'acrostics generator',
      'memorize lists',
      'improve memory',
      'remember words',
      'define words',
      'study tool',
      'learning tool'
    ],
    contentUrl: 'https://learnfactsquick.com/#/alphabet_acrostics_generator',
    nonPersonalizedAds: true,
  );

  // ─────────────────────────────────────────────────────────────
  // AD UNIT IDS
  // ─────────────────────────────────────────────────────────────
  static String get _bannerAdUnitId {
    if (kIsWeb) return '';
    if (Platform.isAndroid) {
      return Globals.isTesting
          ? 'ca-app-pub-3940256099942544/6300978111'
          : 'ca-app-pub-8514966468184377/3605875610';
    }
    if (Platform.isIOS) {
      return Globals.isTesting
          ? 'ca-app-pub-3940256099942544/2934735716'
          : 'ca-app-pub-8514966468184377/2831979873';
    }
    return '';
  }

  static String get _interstitialAdUnitId {
    if (kIsWeb) return '';
    if (Platform.isAndroid) {
      return Globals.isTesting
          ? 'ca-app-pub-3940256099942544/1033173712'
          : 'ca-app-pub-8514966468184377/1433817858';
    }
    if (Platform.isIOS) {
      return Globals.isTesting
          ? 'ca-app-pub-3940256099942544/4411468910'
          : 'ca-app-pub-8514966468184377/1586501727';
    }
    return '';
  }

  static String get _rewardedAdUnitId {
    if (kIsWeb) return '';
    if (Platform.isAndroid) {
      return Globals.isTesting
          ? 'ca-app-pub-3940256099942544/5224354917'
          : 'ca-app-pub-8514966468184377/5277285205';
    }
    if (Platform.isIOS) {
      return Globals.isTesting
          ? 'ca-app-pub-3940256099942544/1712485313'
          : 'ca-app-pub-8514966468184377/9232337506';
    }
    return '';
  }

  // ─────────────────────────────────────────────────────────────
  // BANNER
  // ─────────────────────────────────────────────────────────────
  static bool get isBannerReady => _isBannerReady;

  static Future<BannerAd?> createBanner({
    VoidCallback? onLoaded,
    Function(LoadAdError error)? onFailed,
  }) async {
    debugPrint(
      "createBanner called, kIsWeb: $kIsWeb, isAds: ${Globals.isAds}, bannerAdUnitId: $_bannerAdUnitId ",
    );
    if (kIsWeb || !Globals.isAds || _bannerAdUnitId.isEmpty) {
      return null;
    }

    final ad = BannerAd(
      adUnitId: _bannerAdUnitId,
      size: AdSize.banner,
      request: request,
      listener: BannerAdListener(
        onAdLoaded: (_) {
          _isBannerReady = true;
          onLoaded?.call();
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('Banner failed: $error');
          ad.dispose();
          onFailed?.call(error);
        },
      ),
    );
    debugPrint("createBanner loading ad...");
    await ad.load();
    return ad;
  }

  static Widget? bottomBanner({
    BannerAd? bannerAd,
    Color backgroundColor = Colors.white,
  }) {
    //bool adsDisabled = await areAdsDisabled();
    if (!Globals.isAds || !_isBannerReady || bannerAd == null) {
      return null;
    }

    return SafeArea(
      child: Container(
        color: backgroundColor,
        height: bannerAd.size.height.toDouble(),
        width: bannerAd.size.width.toDouble(),
        child: AdWidget(ad: bannerAd),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // INTERSTITIAL
  // ─────────────────────────────────────────────────────────────

  static void loadInterstitial() {
    if (kIsWeb || !Globals.isAds) return;
    if (_interstitialAd != null) return;

    InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: request,
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('Interstitial loaded');
          _interstitialAd = ad;
          _interstitialLoadAttempts = 0;

          ad.setImmersiveMode(true);

          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              debugPrint('Interstitial dismissed');
              ad.dispose();
              _interstitialAd = null;

              _pendingInterstitialComplete?.call();
              _pendingInterstitialComplete = null;

              loadInterstitial();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              debugPrint('Interstitial failed to show: $error');
              ad.dispose();
              _interstitialAd = null;

              _pendingInterstitialComplete?.call();
              _pendingInterstitialComplete = null;

              loadInterstitial();
            },
          );
        },
        onAdFailedToLoad: (error) {
          debugPrint('Interstitial failed to load: $error');
          _interstitialAd = null;
          _interstitialLoadAttempts++;

          if (_interstitialLoadAttempts < _maxFailedLoadAttempts) {
            loadInterstitial();
          }
        },
      ),
    );
  }

  static Future<void> showInterstitialAd(VoidCallback onComplete) async {
    debugPrint(
      "showInterstitial called, kIsWeb: $kIsWeb, isAds: ${Globals.isAds}, interstitialAd: $_interstitialAd ",
    );
    await setAdsDisabled();
    if (kIsWeb || !Globals.isAds || _interstitialAd == null) {
      debugPrint(
          "showInterstitial Not showing interstitial: web: $kIsWeb, isAds: ${Globals.isAds}, interstitialAd: $_interstitialAd");
      onComplete();
      return;
    }
    final randomValue = _random.nextInt(1000);
    debugPrint(
      "showInterstitial randomValue: $randomValue, showInterstitialPerThousand: $showInterstitialPerThousand ",
    );
    final shouldShow = randomValue < showInterstitialPerThousand;
    if (!shouldShow) {
      debugPrint("showInterstitial shouldShow is false, skipping ad");
      onComplete();
      return;
    }

    _pendingInterstitialComplete = onComplete;

    debugPrint('showInterstitial Showing interstitial');
    _interstitialAd!.show();
    // ❌ DO NOT null or dispose here
  }

  static void loadRewardedAd() {
    debugPrint("loadRewardedAd called");
    if (kIsWeb || _rewardedAdUnitId.isEmpty) {
      return;
    }
    if (_rewardedAd != null) return;
    RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint("Rewarded Ad loaded");
          _rewardedAd = ad;
        },
        onAdFailedToLoad: (error) {
          debugPrint("Rewarded Ad failed to load: $error");
          _rewardedAd = null;
        },
      ),
    );
  }

  static void showRewardedAd(VoidCallback onRewardEarned) {
    if (_rewardedAd == null) return;

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        loadRewardedAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        loadRewardedAd();
      },
    );

    _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        onRewardEarned();
      },
    );

    _rewardedAd = null;
  }

  static Future<void> enableAdRemoval() async {
    final prefs = await SharedPreferences.getInstance();
    final expireTime = DateTime.now().add(Duration(hours: 24));
    //TEST: final expireTime = DateTime.now().add(Duration(minutes: 1));
    await prefs.setInt(
      'REMOVE_ADS_EXPIRE_MS',
      expireTime.millisecondsSinceEpoch,
    );
  }

  static Future<void> setAdsDisabled() async {
    final prefs = await SharedPreferences.getInstance();
    final expireMillis = prefs.getInt('REMOVE_ADS_EXPIRE_MS');
    if (expireMillis == null) return;
    bool isDisabled = DateTime.now().millisecondsSinceEpoch < expireMillis;
    Globals.isAds = !isDisabled;
  }

  static void disposeInterstitial() {
    debugPrint("ads.disposeInterstitial called");
    _interstitialAd?.dispose();
    _interstitialAd = null;
  }

  static void disposRewarded() {
    debugPrint("ads.disposRewarded called");
    _rewardedAd?.dispose();
    _rewardedAd = null;
  }

  // ─────────────────────────────────────────────────────────────
  // FULL CLEANUP
  // ─────────────────────────────────────────────────────────────
  static void disposeAll() {
    debugPrint("ads.disposeAll called");
    disposeInterstitial();
    disposRewarded();
  }

  static Future<void> checkAds() async {
    await setAdsDisabled();
    if (Globals.isAds) {
      loadInterstitial();
      loadRewardedAd();
    }
  }
}
