#include <dlib/dnn.h>
#include <dlib/image_processing/frontal_face_detector.h>
#include <dlib/image_processing.h>
#include <dlib/image_io.h>
#include <iostream>

using namespace dlib;
using namespace std;

// The DNN face recognition model
template <template <int,template<typename>class,int,typename> class block, int N, template<typename>class BN, typename SUBNET>
using residual = add_prev1<block<N,BN,1,tag1<SUBNET>>>;

template <template <int,template<typename>class,int,typename> class block, int N, template<typename>class BN, typename SUBNET>
using residual_down = add_prev2<avg_pool<2,2,2,2,skip1<tag2<block<N,BN,2,tag1<SUBNET>>>>>>;

template <int N, template <typename> class BN, int stride, typename SUBNET> 
using block  = BN<con<N,3,3,1,1,relu<BN<con<N,3,3,stride,stride,SUBNET>>>>>;

template <int N, typename SUBNET> using ares      = relu<residual<block,N,affine,SUBNET>>;
template <int N, typename SUBNET> using ares_down = relu<residual_down<block,N,affine,SUBNET>>;

template <typename SUBNET> using alevel0 = ares_down<256,SUBNET>;
template <typename SUBNET> using alevel1 = ares<256,ares<256,ares_down<256,SUBNET>>>;
template <typename SUBNET> using alevel2 = ares<128,ares<128,ares_down<128,SUBNET>>>;
template <typename SUBNET> using alevel3 = ares<64,ares<64,ares<64,ares_down<64,SUBNET>>>>;
template <typename SUBNET> using alevel4 = ares<32,ares<32,ares<32,SUBNET>>>;

using anet_type = loss_metric<fc_no_bias<128,avg_pool_everything<
                            alevel0<
                            alevel1<
                            alevel2<
                            alevel3<
                            alevel4<
                            max_pool<3,3,2,2,relu<affine<con<32,7,7,2,2,
                            input_rgb_image_sized<150>
                            >>>>>>>>>>>>;

// Calculate Euclidean distance between two face descriptors
double calculate_face_distance(const matrix<float,0,1>& face_desc1, 
                             const matrix<float,0,1>& face_desc2) {
    return length(face_desc1 - face_desc2);
}

int main(int argc, char** argv) {
    try {
        if (argc != 2) {
            cout << "Usage: " << argv[0] << " <image_file>\n";
            return 1;
        }

        // Load models
        shape_predictor sp;
        deserialize("shape_predictor_68_face_landmarks.dat") >> sp;
        
        anet_type net;
        deserialize("dlib_face_recognition_resnet_model_v1.dat") >> net;

        // Load image
        matrix<rgb_pixel> img;
        load_image(img, argv[1]);

        // Detect faces
        frontal_face_detector detector = get_frontal_face_detector();
        std::vector<rectangle> faces = detector(img);

        // Process each face
        std::vector<matrix<float,0,1>> face_descriptors;
        for (size_t i = 0; i < faces.size(); ++i) {
            // Get facial landmarks
            full_object_detection shape = sp(img, faces[i]);
            cout << "Face " << i + 1 << " has " << shape.num_parts() << " landmarks.\n";

            // Print some landmark positions (e.g., eyes)
            cout << "Left eye:  (" << shape.part(36).x() << "," << shape.part(36).y() << ")\n";
            cout << "Right eye: (" << shape.part(45).x() << "," << shape.part(45).y() << ")\n";

            // Get face descriptor (for recognition)
            matrix<rgb_pixel> face_chip;
            extract_image_chip(img, get_face_chip_details(shape,150,0.25), face_chip);
            matrix<float,0,1> face_desc = matrix_cast<float>(mat(net(face_chip)));
            face_descriptors.push_back(face_desc);

            cout << "Face descriptor size: " << face_desc.size() << endl;
        }

        // Compare faces if we found more than one
        if (face_descriptors.size() >= 2) {
            cout << "\nComparing faces:\n";
            for (size_t i = 0; i < face_descriptors.size(); ++i) {
                for (size_t j = i + 1; j < face_descriptors.size(); ++j) {
                    double distance = calculate_face_distance(face_descriptors[i], face_descriptors[j]);
                    cout << "Distance between face " << i+1 << " and face " << j+1 
                         << ": " << distance << endl;
                    // Generally, distance < 0.6 means same person
                    cout << "These faces are " 
                         << (distance < 0.6 ? "likely the same person" : "different people")
                         << endl;
                }
            }
        }

        cout << "\nTotal faces found: " << faces.size() << endl;

    } catch (serialization_error& e) {
        cout << "Model file serialization error: " << e.what() << endl;
        return 1;
    } catch (std::exception& e) {
        cout << "Error: " << e.what() << endl;
        return 1;
    }
}
