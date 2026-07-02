-- Dummy Data: Aplikasi Komiku
-- Jalankan SETELAH komiku_schema.sql (kategori sudah keisi dari situ)

-- ==========================
-- USERS (password = "password123", ganti pakai hash asli dari app kamu)
-- ==========================
INSERT INTO users (id, name, username, email, password, avatar, bio) VALUES
(1, 'Jonathan Winata', 'jonathanw', 'jonathan@mail.com', '$2y$10$abcdefghijklmnopqrstuv', NULL, 'Suka baca komik action'),
(2, 'Dewi Lestari', 'dewilestari', 'dewi@mail.com', '$2y$10$abcdefghijklmnopqrstuv', NULL, 'Komikus amatir'),
(3, 'Budi Santoso', 'budisan', 'budi@mail.com', '$2y$10$abcdefghijklmnopqrstuv', NULL, NULL),
(4, 'Rina Amalia', 'rina_a', 'rina@mail.com', '$2y$10$abcdefghijklmnopqrstuv', NULL, 'Suka horor & thriller'),
(5, 'Andi Firmansyah', 'andifirman', 'andi@mail.com', '$2y$10$abcdefghijklmnopqrstuv', NULL, NULL);

-- ==========================
-- COMICS
-- ==========================
INSERT INTO comics (id, user_id, title, slug, synopsis, poster, status, view_count) VALUES
(1, 2, 'Ksatria Bayangan', 'ksatria-bayangan', 'Seorang pemuda menemukan kekuatan tersembunyi untuk melawan kegelapan yang mengancam kotanya.', 'posters/ksatria-bayangan.jpg', 'ongoing', 1520),
(2, 2, 'Kucing Gila', 'kucing-gila', 'Komedi slice of life tentang kucing rumahan yang punya kepribadian absurd.', 'posters/kucing-gila.jpg', 'ongoing', 890),
(3, 3, 'Rumah di Ujung Jalan', 'rumah-di-ujung-jalan', 'Keluarga yang pindah ke rumah tua mulai mengalami kejadian aneh tiap malam.', 'posters/rumah-ujung-jalan.jpg', 'completed', 2310),
(4, 5, 'Cinta di Musim Hujan', 'cinta-di-musim-hujan', 'Kisah cinta dua mahasiswa yang bertemu kembali setelah 5 tahun berpisah.', 'posters/cinta-musim-hujan.jpg', 'ongoing', 675),
(5, 3, 'Dunia Lain', 'dunia-lain', 'Petualangan fantasi seorang gadis yang terjebak di dimensi paralel.', 'posters/dunia-lain.jpg', 'ongoing', 1104),
(6, 5, 'Sehari di Kantor', 'sehari-di-kantor', 'Komedi kantoran sehari-hari yang absurd dan relatable.', 'posters/sehari-kantor.jpg', 'ongoing', 430);

-- ==========================
-- COMIC_CATEGORY (id kategori mengikuti urutan seed di schema: 1 Action,2 Komedi,3 Horor,4 Romance,5 Slice of Life,6 Fantasy)
-- ==========================
INSERT INTO comic_category (comic_id, category_id) VALUES
(1, 1), -- Ksatria Bayangan: Action
(1, 6), -- + Fantasy
(2, 2), -- Kucing Gila: Komedi
(2, 5), -- + Slice of Life
(3, 3), -- Rumah di Ujung Jalan: Horor
(4, 4), -- Cinta di Musim Hujan: Romance
(5, 6), -- Dunia Lain: Fantasy
(5, 1), -- + Action
(6, 2), -- Sehari di Kantor: Komedi
(6, 5); -- + Slice of Life

-- ==========================
-- CHAPTERS
-- ==========================
INSERT INTO chapters (id, comic_id, chapter_number, title) VALUES
(1, 1, 1, 'Awal Kegelapan'),
(2, 1, 2, 'Kekuatan Terbangun'),
(3, 2, 1, 'Kucingku Ngambek'),
(4, 3, 1, 'Pindah Rumah'),
(5, 3, 2, 'Suara di Malam Hari'),
(6, 4, 1, 'Pertemuan Kembali'),
(7, 5, 1, 'Gerbang Dimensi'),
(8, 6, 1, 'Senin Pagi yang Kacau');

-- ==========================
-- CHAPTER_PAGES (3 halaman per chapter, contoh)
-- ==========================
INSERT INTO chapter_pages (chapter_id, page_number, image) VALUES
(1, 1, 'pages/ch1/1.jpg'), (1, 2, 'pages/ch1/2.jpg'), (1, 3, 'pages/ch1/3.jpg'),
(2, 1, 'pages/ch2/1.jpg'), (2, 2, 'pages/ch2/2.jpg'), (2, 3, 'pages/ch2/3.jpg'),
(3, 1, 'pages/ch3/1.jpg'), (3, 2, 'pages/ch3/2.jpg'),
(4, 1, 'pages/ch4/1.jpg'), (4, 2, 'pages/ch4/2.jpg'), (4, 3, 'pages/ch4/3.jpg'),
(5, 1, 'pages/ch5/1.jpg'), (5, 2, 'pages/ch5/2.jpg'),
(6, 1, 'pages/ch6/1.jpg'), (6, 2, 'pages/ch6/2.jpg'), (6, 3, 'pages/ch6/3.jpg'),
(7, 1, 'pages/ch7/1.jpg'), (7, 2, 'pages/ch7/2.jpg'),
(8, 1, 'pages/ch8/1.jpg'), (8, 2, 'pages/ch8/2.jpg');

-- ==========================
-- RATINGS
-- ==========================
INSERT INTO ratings (comic_id, user_id, rating) VALUES
(1, 1, 5), (1, 3, 4), (1, 4, 5),
(2, 1, 4), (2, 4, 3),
(3, 2, 5), (3, 1, 5), (3, 5, 4),
(4, 2, 4), (4, 3, 3),
(5, 4, 4), (5, 1, 5),
(6, 2, 3), (6, 1, 4);

-- ==========================
-- COMMENTS (parent_id NULL = komentar utama, ada isi = reply)
-- ==========================
INSERT INTO comments (id, comic_id, user_id, parent_id, content) VALUES
(1, 1, 3, NULL, 'Gambarnya keren banget, ditunggu chapter selanjutnya!'),
(2, 1, 2, 1, 'Setuju, art style-nya beda dari komik lain'),
(3, 1, 4, NULL, 'Plot twist di chapter 2 gak nyangka'),
(4, 3, 1, NULL, 'Serem parah pas bagian suara di lantai atas'),
(5, 3, 5, 4, 'Iya itu bikin merinding'),
(6, 4, 3, NULL, 'Baper baca ini huhu'),
(7, 5, 2, NULL, 'World building-nya detail banget'),
(8, 6, 4, NULL, 'Relate banget sama kerjaan sehari-hari');

-- ==========================
-- COMIC_VIEWS (opsional, contoh beberapa log view)
-- ==========================
INSERT INTO comic_views (comic_id, user_id, ip_address) VALUES
(1, 3, NULL), (1, 4, NULL), (1, NULL, '192.168.1.10'),
(3, 1, NULL), (3, NULL, '192.168.1.15'),
(4, 2, NULL);
