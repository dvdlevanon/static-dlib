/*
 * Simple face detection example using statically linked DLIB
 * Demonstrates basic usage without GUI dependencies
 */

#include <stdio.h>
#include <dlib/image_processing/frontal_face_detector.h>
#include <dlib/image_io.h>

int main(int argc, char** argv) {
    if (argc != 2) {
        printf("Usage: %s <image_file>\n", argv[0]);
        return 1;
    }

    try {
        // Load the image
        dlib::array2d<unsigned char> img;
        dlib::load_image(img, argv[1]);

        // Get the face detector
        dlib::frontal_face_detector detector = dlib::get_frontal_face_detector();

        // Upscale image to find smaller faces
        dlib::pyramid_up(img);

        // Detect faces
        std::vector<dlib::rectangle> faces = detector(img);

        // Print results
        printf("Found %zu faces in the image.\n", faces.size());
        
        for (size_t i = 0; i < faces.size(); i++) {
            const dlib::rectangle& face = faces[i];
            printf("Face %zu: Left=%ld, Top=%ld, Right=%ld, Bottom=%ld\n",
                   i + 1,
                   face.left(),
                   face.top(),
                   face.right(),
                   face.bottom());
        }

        return 0;
    }
    catch (std::exception& e) {
        printf("Error: %s\n", e.what());
        return 1;
    }
}
