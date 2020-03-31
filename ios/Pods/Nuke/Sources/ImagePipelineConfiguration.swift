// The MIT License (MIT)
//
// Copyright (c) 2015-2019 Alexander Grebenyuk (github.com/kean).

import Foundation

extension ImagePipeline {
    public struct Configuration {
        // MARK: - Dependencies

        /// Image cache used by the pipeline.
        public var imageCache: ImageCaching?

        /// Data loader used by the pipeline.
        public var dataLoader: DataLoading

        /// Data cache used by the pipeline.
        public var dataCache: DataCaching?

        /// Default implementation uses shared `ImageDecoderRegistry` to create
        /// a decoder that matches the context.
        public var makeImageDecoder: (ImageDecodingContext) -> ImageDecoding = {
            return ImageDecoderRegistry.shared.decoder(for: $0)
        }

        /// Returns `ImageEncoder()` by default.
        public var makeImageEncoder: (ImageEncodingContext) -> ImageEncoding = { _ in
            return ImageEncoder()
        }

        // MARK: - Operation Queues

        /// Data loading queue. Default maximum concurrent task count is 6.
        public var dataLoadingQueue = OperationQueue()

        /// Data caching queue. Default maximum concurrent task count is 2.
        public var dataCachingQueue = OperationQueue()

        /// Image decoding queue. Default maximum concurrent task count is 1.
        public var imageDecodingQueue = OperationQueue()

        /// Image encodign queue. Default maximum concurrent task count is 1.
        public var imageEncodingQueue = OperationQueue()

        /// Image processing queue. Default maximum concurrent task count is 2.
        public var imageProcessingQueue = OperationQueue()

        #if !os(macOS)
        /// Image decompressing queue. Default maximum concurrent task count is 2.
        public var imageDecompressingQueue = OperationQueue()
        #endif

        // MARK: - Options

        #if !os(macOS)
        /// Decompresses the loaded images. `true` by default.
        ///
        /// Decompressing compressed image formats (such as JPEG) can significantly
        /// improve drawing performance as it allows a bitmap representation to be
        /// created in a background rather than on the main thread.
        public var isDecompressionEnabled = true
        #endif

        /// `true` by default. If `true`, original image data provided by
        /// `dataLoader` will be stored in a custom `dataCache` provided in the
        /// configuration.
        ///
        /// If the value is set to `true`, you must also provide `dataCache`
        /// instance in the configuration.
        public var isDataCachingForOriginalImageDataEnabled = true

        /// `false` by default. If `true`, the images for which one or more
        /// processors were specified will be encoded and stored in data cache.
        ///
        /// If the value is set to `true`, you must also provide `dataCache`
        /// instance in the configuration.
        //
        /// - WARNING: When enabled every intermediate processed image will be
        /// stored in disk data cache if it is enabled. To avoid storing
        /// unwanted intermediate images, use `ImageProcessor.Composition` to
        /// compose multiple processors into a single one.
        public var isDataCachingForProcessedImagesEnabled = false

        /// `true` by default. If `true` the pipeline avoids duplicated work when
        /// loading images. The work only gets cancelled when all the registered
        /// requests are. The pipeline also automatically manages the priority of the
        /// deduplicated work.
        ///
        /// Let't take this two requests for example:
        ///
        /// ```swift
        /// let url = URL(string: "http://example.com/image")
        /// pipeline.loadImage(with: ImageRequest(url: url, processors: [
        ///     ImageProcessor.Resize(size: CGSize(width: 44, height: 44)),
        ///     ImageProcessor.GaussianBlur(radius: 8)
        /// ]))
        /// pipeline.loadImage(with: ImageRequest(url: url, processors: [
        ///     ImageProcessor.Resize(size: CGSize(width: 44, height: 44))
        /// ]))
        /// ```
        ///
        /// Nuke will load the image data only once, resize the image once and
        /// apply the blur also only once. There is no duplicated work done at
        /// any stage.
        public var isDeduplicationEnabled = true

        /// `true` by default. It `true` the pipeline will rate limits the requests
        /// to prevent trashing of the underlying systems (e.g. `URLSession`).
        /// The rate limiter only comes into play when the requests are started
        /// and cancelled at a high rate (e.g. scrolling through a collection view).
        public var isRateLimiterEnabled = true

        /// `false` by default. If `true` the pipeline will try to produce a new
        /// image each time it receives a new portion of data from data loader.
        /// The decoder used by the image loading session determines whether
        /// to produce a partial image or not.
        public var isProgressiveDecodingEnabled = false

        /// If the data task is terminated (either because of a failure or a
        /// cancellation) and the image was partially loaded, the next load will
        /// resume where it was left off. Supports both validators (`ETag`,
        /// `Last-Modified`). The resumable downloads are enabled by default.
        public var isResumableDataEnabled = true

        // MARK: - Options (Shared)

        /// If `true` pipeline will detects GIFs and set `animatedImageData`
        /// (`UIImage` property). It will also disable processing of such images,
        /// and alter the way cache cost is calculated. However, this will not
        /// enable actual animated image rendering. To do that take a look at
        /// satellite projects (FLAnimatedImage and Gifu plugins for Nuke).
        /// `false` by default (to preserve resources).
        public static var isAnimatedImageDataEnabled = false

        /// `false` by default. If `true`, enables `os_signpost` logging for
        /// measuring performance. You can visually see all the performance
        /// metrics in `os_signpost` Instrument. For more information see
        /// https://developer.apple.com/documentation/os/logging and
        /// https://developer.apple.com/videos/play/wwdc2018/405/.
        public static var isSignpostLoggingEnabled = false

        // MARK: - Initializer

        /// Creates a default configuration.
        /// - parameter dataLoader: `DataLoader()` by default.
        /// - parameter imageCache: `Cache.shared` by default.
        public init(dataLoader: DataLoading = DataLoader(), imageCache: ImageCaching? = ImageCache.shared) {
            self.dataLoader = dataLoader
            self.imageCache = imageCache

            self.dataLoadingQueue.maxConcurrentOperationCount = 6
            self.dataCachingQueue.maxConcurrentOperationCount = 2
            self.imageDecodingQueue.maxConcurrentOperationCount = 1
            self.imageEncodingQueue.maxConcurrentOperationCount = 1
            self.imageProcessingQueue.maxConcurrentOperationCount = 2
            #if !os(macOS)
            self.imageDecompressingQueue.maxConcurrentOperationCount = 2
            #endif
        }
    }
}
