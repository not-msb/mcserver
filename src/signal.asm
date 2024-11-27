SIGINT = 2

struc sigaction handler, mask, flags, restorer {
    .sa_handler dq handler
    .sa_mask dq mask
    .sa_flags dd flags
    .sa_restorer dq restorer
}
