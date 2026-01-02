import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:NutriViet/core/constants/colors.dart';
import 'package:NutriViet/core/services/news_service.dart';
import 'package:NutriViet/features/home/news_detail_screen.dart';

class NewsSection extends StatelessWidget {
  const NewsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Health News",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              Text(
                "Source: VnExpress",
                style: TextStyle(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold
                ),
              ),
            ],
          ),
        ),

        SizedBox(
          height: 250,
          child: FutureBuilder<List<NewsArticle>>(
            future: NewsService.fetchHealthNews(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: AppColors.primary));
              }
              if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                    child: Text(
                      "Unable to load news at the moment.",
                      style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                    )
                );
              }

              final articles = snapshot.data!;

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(left: 20, right: 10),
                itemCount: articles.length,
                itemBuilder: (context, index) {
                  final article = articles[index];
                  return Container(
                    width: 280,
                    margin: const EdgeInsets.only(right: 16, bottom: 10),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => NewsDetailScreen(newsUrl: article.link),
                          ),
                        );
                      },
                      child: Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        color: Theme.of(context).cardTheme.color,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                              child: article.imageUrl.isNotEmpty
                                  ? CachedNetworkImage(
                                imageUrl: article.imageUrl,
                                height: 140,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(color: Colors.grey[200]),
                                errorWidget: (context, url, error) => Container(
                                  height: 140, color: Colors.grey[300],
                                  child: const Icon(Icons.broken_image, color: Colors.grey),
                                ),
                              )
                                  : Container(
                                height: 140,
                                color: Colors.grey[300],
                                child: const Icon(Icons.image_not_supported, color: Colors.grey),
                              ),
                            ),

                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Text(
                                article.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  height: 1.3,
                                  color: Theme.of(context).textTheme.bodyLarge?.color,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}