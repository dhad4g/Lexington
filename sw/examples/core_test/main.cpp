

extern "C" void inst_test();
extern "C" void check(int test_value, int correct_value);
extern "C" void error();
extern "C" void success();

int main() {

    inst_test();

    success();

}
