# Day Track Architecture Guide

This project follows a **Feature-First (Feature-Driven) Architecture** combined with a layered approach (similar to Clean Architecture) for each feature. This ensures that the codebase remains scalable, modular, and easy to maintain as new features are added.

## Directory Structure

```text
lib/
 ├── core/                    # Ortak kullanılan (uygulama geneli) dosyalar
 │   ├── constants/           # Sabitler (renkler, stringler, ölçüler vb.)
 │   ├── theme/               # Tema ayarları (ışık/karanlık mod, tipografi)
 │   ├── utils/               # Yardımcı fonksiyonlar (formatlayıcılar, extensionlar vb.)
 │   └── services/            # Ortak servisler (Local storage, API istemcisi vb.)
 │
 ├── features/                # Uygulamanın temel özellikleri (Feature'lar)
 │   └── home/                # Örnek bir feature (Ana Sayfa)
 │       ├── data/            # Veri katmanı (Modeller, Repository implementasyonları, API çağrıları)
 │       ├── domain/          # İş mantığı katmanı (Entity'ler, UseCase'ler, Repository arayüzleri)
 │       └── presentation/    # Arayüz katmanı
 │           ├── pages/       # Sayfalar (Örn: HomePage)
 │           └── widgets/     # Sadece bu feature'a ait özel widget'lar
 │
 └── main.dart                # Uygulamanın giriş noktası
```

## Neden Bu Mimari?
1. **Ölçeklenebilirlik (Scalability):** Proje büyüdükçe her yeni özelliği (feature) kendi klasörü içinde izole bir şekilde geliştirebiliriz.
2. **Bakım Kolaylığı (Maintainability):** Bir hata çıktığında (örneğin ana sayfada), sadece `features/home` klasörüne odaklanmak yeterlidir.
3. **Tekrar Kullanılabilirlik (Reusability):** Tüm özellikleri ilgilendiren bileşenler ve servisler `core/` altında toplanarak kod tekrarı önlenir.

## Katmanların Görevleri (MVVM / Clean)
* **Presentation (Arayüz):** Kullanıcının gördüğü her şey burada yer alır. (UI, State Management vb.)
* **Domain (İş Mantığı):** Uygulamanın temel kuralları ve veri yapıları buradadır. Dış dünyaya (UI veya Database) bağımlı değildir.
* **Data (Veri):** Dış kaynaklardan (API, veritabanı, SharedPreferences) verilerin çekildiği, modellendiği ve Domain katmanına sunulduğu yerdir.
