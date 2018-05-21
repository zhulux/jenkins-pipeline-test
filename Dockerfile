FROM ubuntu

RUN /bin/bash -c echo "This is simple test case! "
ENV mycustomenv1="KaLa is Dog." \
    otherenv="God is Girl!"
CMD ["for i in `seq 200`; do echo $i;slepp 1;done"]
